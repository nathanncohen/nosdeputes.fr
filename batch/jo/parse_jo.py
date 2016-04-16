#!/usr/bin/env python
# -*- coding: utf8 -*-
# Ce script extrait les présences en commission du Journal Officiel
# Usage : parse_jo.py chamber [day]
# "chamber" peut prendre pour valeur : "an" ou "senat" ; "day" doit être une date de la forme "2016-04-15", si omis, la date du jour sera utilisée
import re, os, sys, urllib2, json
from datetime import date, time, datetime
from bs4 import BeautifulSoup

def date_iso(datestr):
  month = {
    u"janvier": "01",
    u"février": "02",
    u"mars": "03",
    u"avril": "04",
    u"mai": "05",
    u"juin": "06",
    u"juillet": "07",
    u"août": "08",
    u"septembre": "09",
    u"octobre": "10",
    u"novembre": "11",
    u"décembre": "12",
  }
  d = datestr.split(' ')
  if d[1] == '1er':
    d[1] = '01'
  if len(d[1]) == 1:
    d[1] = '0'+d[1]
  dateiso = d[3][0:4]+'-'+month[d[2]]+'-'+d[1]
  if re.search(reg['date'], dateiso) is not None:
    return dateiso
  else:
    return datestr

reg = {}
reg['date'] = '^([0-9]{4})-([0-9]{2})-([0-9]{2})$'
reg['com'] = '^Commissions'
reg['start'] = u'^[0-9]{0,2}\.? ?Membres présents ou excusés'
reg['commission'] = u'(.*) :$'
reg['reunion'] = u'^Réunion du (.*) à (.*) :'
reg['presents'] = u'^Présents. (-|:) (.*)'
reg['excuses'] = u'^Excusés?. (-|:) (.*)'
reg['assistent'] = u'^Assistai.* (-|:) (.*)'
reg['civilite'] = u' ?(Mme|M\.) '

# Paramètres
try:
  chamber = sys.argv[1]
except IndexError:
  sys.exit('Le 1er argument est obligatoire, il doit être "an ou "senat"')
try:
  day = sys.argv[2]
except IndexError:
  day = str(datetime.now().date())

prefix = 'https://www.legifrance.gouv.fr'

if chamber == 'an':
  text_link = u'Commissions et organes de contrôle'
elif chamber == 'senat':
  text_link = u'Commissions'
else:
  sys.exit('Le 1er argument doit être "an" ou "senat"')

if re.search(reg['date'], day) is not None:
  m = re.search(reg['date'], day)
  date_fr = m.group(3)+'/'+m.group(2)+'/'+m.group(1)
  jo_eli = prefix+'/eli/jo/'+m.group(1)+'/'+str(int(m.group(2)))+'/'+str(int(m.group(3)))
else:
  sys.exit('Le 2ème argument doit être une date de la forme "2016-04-15"')

# Repertoires
if not os.path.exists('./html'):
  os.makedirs('./html')
if not os.path.exists('./json'):
  os.makedirs('./json')

# Sommaire JO
summary = urllib2.urlopen(jo_eli)
soup = BeautifulSoup(summary.read(), "lxml-xml")

if soup.title.string.strip().startswith(u'Recherche'):
  sys.exit(chamber.upper()+' '+date_fr+' no JO '+jo_eli)

else:
  # Sauvegarde sommaire
  with open("html/sommaire_"+day+".html", "wb") as file:
    file.write(soup.prettify("utf-8"))

  data = {}
  commission_link = False

  for link in soup.find_all('a'):
    link_string = unicode(link.string).strip()
    if re.search(reg['com'], link_string, re.IGNORECASE) is not None:

      data['source'] = 'Journal officiel du '+date_fr

      # Commission
      if link_string == text_link:
        commission_link = True
        com_link = prefix+link.get('href')
        coms_doc = urllib2.urlopen(com_link)
        soup = BeautifulSoup(coms_doc.read(), "lxml-xml")

        # Sauvegarde commissions
        with open("html/coms_"+chamber+"_"+day+".html", "wb") as file:
          file.write(soup.prettify("utf-8"))

        t = soup.find_all("div", "article")

        for br in t[0].findAll('br'):
          br.replace_with(os.linesep)

        on = False

        com_text = ''

        for line in t[0].get_text().split(os.linesep):
          line = line.strip()

          # Détecter début
          if re.search(reg['start'], line, re.IGNORECASE) is not None:
            on = True

          # Pre-process
          if on and line:
            if line.startswith(u'Présent') is False and line.startswith(u'Excusé') is False and line.startswith(u'Assistai') is False and line.endswith(u' :') is False:
              line = line+u' :'

            com_text += line+os.linesep

        json_file = ''

        for line in com_text.split(os.linesep):

          if re.search(reg['commission'], line) is not None:

            if re.search(reg['reunion'], line, re.IGNORECASE) is not None:
              m = re.search(reg['reunion'], line, re.IGNORECASE)
              data['reunion'] = date_iso(m.group(1))
              data['session'] = m.group(2).replace(' :', '').replace(' h ', ':').replace(' heures', ':00')
            else:
              m = re.search(reg['commission'], line)
              data['commission'] = m.group(1)

          if re.search(reg['presents'], line, re.IGNORECASE) is not None:
            m = re.search(reg['presents'], line, re.IGNORECASE)
            presents = re.sub(reg['civilite'], "", m.group(2)).split(',')

            for present in presents:
              data['depute'] = present
              json_file += json.dumps(data, separators=(',',':'))+os.linesep

          if re.search(reg['assistent'], line, re.IGNORECASE) is not None:
            m = re.search(reg['assistent'], line, re.IGNORECASE)
            presents = re.sub(reg['civilite'], "", m.group(2)).split(',')

            for present in presents:
              data['depute'] = present
              json_file += json.dumps(data, separators=(',',':'))+os.linesep

        if not json_file:
          sys.exit(chamber.upper()+' '+date_fr+' no presence '+com_link)
        else:
          print(json_file.strip())
          #with open("json/"+chamber+"_"+day+".html", "wb") as file:
          #  file.write(json_file.strip())

if not commission_link:
  sys.exit(chamber.upper()+' '+date_fr+' no commission '+jo_eli)


