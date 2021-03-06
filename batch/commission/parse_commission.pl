#!/usr/bin/perl

$file = $url = shift;
#use HTML::TokeParser;
$url =~ s/^[^\/]+\///;
$url =~ s/_/\//g;
$url =~ s/commissions\/elargies/commissions_elargies/;
$source = $url;
$baseurl = $url;
$baseurl =~ s/\/[^\/]+$/\//;
$rooturl = $url;
$rooturl =~ s/^([^\/]+)\/.*$/\1/;

if ($url =~ /\/(\d+)-(\d+)\//) {
  $session = '20'.$1.'20'.$2;
} elsif ($url =~ /\/plf(\d+)\//) {
  $annee = $1-1;
  $session = $annee.$1;
}

open(FILE, $file) ;
@string = <FILE>;
$string = "@string";
close FILE;

$string =~ s/\r//g;
$string =~ s/(M\.\s*&nbsp;\s*)+/M. /g;
$string =~ s/&#278;/É/g;

$mois{'janvier'} = '01';
$mois{'février'} = '02';
$mois{'mars'} = '03';
$mois{'avril'} = '04';
$mois{'mai'} = '05';
$mois{'juin'} = '06';
$mois{'juillet'} = '07';
$mois{'août'} = '08';
$mois{'septembre'} = '09';
$mois{'octobre'} = '10';
$mois{'novembre'} = '11';
$mois{'décembre'} = '12';

$heure{'neuf'} = '09';
$heure{'dix'} = '10';
$heure{'onze'} = '11';
$heure{'douze'} = '12';
$heure{'treize'} = '13';
$heure{'quatorze'} = '14';
$heure{'quinze'} = '15';
$heure{'seize'} = '16';
$heure{'dix-sept'} = '17';
$heure{'dix-huit'} = '18';
$heure{'dix-neuf'} = '19';
$heure{'vingt'} = '20';
$heure{'vingt-cinq'} = '25';
$heure{'vingt et une'} = '21';
$heure{'vingt-et-une'} = '21';
$heure{'vingt-deux'} = '22';
$heure{'cinquante'} = '50';
$heure{'quarante'} = '45';
$heure{'quarante-cinq'} = '45';
$heure{'cinquante-cinq'} = '55';
$heure{'trente'} = '30';
$heure{'trente-cinq'} = '35';
$heure{'quinze'} = '15';
$heure{'zéro'} = '00';
$heure{'cinq'} = '00';
$heure{''} = '00';

if ($url =~ /\/plf(\d+)\//) {
  $string2 = $string;
  $string2 =~ s/\n//g;
  $string2 =~ s/\<br\/?\>//ig;
  $string2 =~ s/&nbsp;/ /ig;
  $string2 =~ s/&#8217;/'/ig;
  utf8::decode($string2);
  $string2 =~ s/\x{92}/'/g;
  utf8::encode($string2);
  $string2 =~ s/\s+/ /g;
  $string2 =~ s/^.*>commission (e|é|É)largie<.*>commission des finances.*?>commission d(e l'|(u|e la|es) )//i;
  $string2 =~ s/\(Application de l'article 120 du Règlement(.*)//i;
  $tmpdate = $1;
  $tmpdate =~ s/\<[^>]+>//ig;
  $tmpdate =~ s/^\W+//;
  if ($tmpdate =~ /^(\w+\s+)?(\d+)[erme]*\s+([^\s\d]+)\s+(\d+)/i) {
    $date = sprintf("%04d-%02d-%02d", $4, $mois{lc($3)}, $2);
  }
  $string2 =~ s/\<\/?[^>]+\>//ig;
  $string2 =~ s/^\s+//;
  $string2 =~ s/[^a-z]+$//;
  $string2 =~ s/(,| et) d.*?( Commission|$)/\2/gi;
  $string2 =~ s/ Commission d(u|e la|es) ([a-z])/ - \U\2/gi;
  $string2 =~ s/Assemblée nationale ~.*//i;
  $commission = "Commission élargie : Finances - ".ucfirst($string2);
  $commission =~ s/ - $//;
}

$string =~ s/\s*&(#160|nbsp);\s*/ /ig;
$string =~ s/\s*<b>\s+<\/b>\s*/ /g;
$string =~ s/<\/b>(\s*)<b>/\1/g;
$string =~ s/<b>(\s*[\.,]\s*)<\/b>/\1/g;
$string =~ s/<\/[ub]>\s*,\s*<\/[ub]>/,<u><b>/g;
$string =~ s/(?:<\/?[ub]>)+\s*(\.)?\s*(?:<\/?[ub]>)+/\1<b>/g;
$string =~ s/\. ([A-Z])<\/b>(\w)/.<\/b> \1\2/g;
$string =~ s/<\/?[bu]>/|/g;
$string =~ s/<\/?i>/\//g;

if ($string =~ />Réunion du (\w+\s+)?(\d+)[erme]*\s+([^\s\d]+)\s+(\d+)(?:\s+à\s+(\d+)\s*h(?:eure)?s?\s*(\d*))\.?</) {
  $tmpdate = sprintf("%04d-%02d-%02d", $4, $mois{lc($3)}, $2);
  $heure = sprintf("%02d:%02d", $5, $6 || '00');
}

if ($string =~ /réunion.*commission.*commence[^\.]+à\s+([^\.]+)\s+heures?\s*([^\.]*)\./i) {
  $heure = $heure{$1}.':'.$heure{$2};
}

#utf8::decode($string);
#
#$p = HTML::TokeParser->new(\$string);
#
#while ($t = $p->get_tag('p', 'h1', 'h5')) {
#    print "--".$p->get_text('/'.$t->[0])."\n";
#}
#
#exit;
$cpt = 0;
sub checkout {
    $commission =~ s/"//g;
    if ($commission =~/^\s*Mission d'information\s*$/i && $commission_meta) {
        $commission = $commission_meta;
    }
    if (!$date) {
        $date = $tmpdate;
    }
    $intervention =~ s/"/\\"/g;
    $intervention =~ s/\\\\/\//g;
    $intervention =~ s/\s*(<\/?t(able|[rdh])[^>]*>)\s*/\1/gi;
    $cpt+=10;
    $ts = $cpt;
    $out =  '{"commission": "'.$commission.'", "intervention": "'.$intervention.'", "date": "'.$date.'", "source": "'.$source.'", "heure":"'.$heure.'", "session": "'.$session.'", ';
    if ($intervention && $intervenant) {
	if ($intervenant =~ s/ et M[mes\.]* (l[ea] )?(.*)//) {
            $second = $2;
            if ($fonction2inter{$second}) {
                $second = $fonction2inter{$second};
            }
	    print $out.'"intervenant": "'.$second.'", "timestamp": "'.$ts.'", "fonction": "'.$inter2fonction{$second}."\"}\n";
	    $ts++;
	}
	print $out.'"intervenant": "'.$intervenant.'", "timestamp": "'.$ts.'", "fonction": "'.$inter2fonction{$intervenant}."\"}\n";
    }elsif($intervention) {
	print $out.'"intervenant":"", "timestamp": "'.$ts.'"}'."\n";
    }else {
	return ;
    }
    $commentaire = "";
    $intervenant = "";
    $intervention = "";
}

sub setFonction {
    my $fonction = shift;
    my $intervenant = setIntervenant(shift);
    $fonction =~ s/[^a-zàâéèêëîïôùûü]+$//i;
    $fonction =~ s/<[^>]+>\s*//g;
    $fonction =~ s/<[^>]*$//;
    $fonction =~ s/\///g;
    $fonction =~ s/(n°|[(\s]+)$//;
    $fonction =~ s/\s+[0-9][0-9]?\s*$//;
    my $kfonction = lc($fonction);
    $kfonction =~ s/[^a-zéàè]+/ /gi;
    if ($fonction2inter{$kfonction} && !$intervenant) {
        $intervenant = $fonction2inter{$kfonction};
        return $intervenant;
    }
    $fonction2inter{$kfonction} = $intervenant;
    #print "TEST $kfonction -> $intervenant\n";
    if ($fonction =~ /(ministre déléguée?).*(chargé.*$)/i) {
        $kfonction = "$1 $2";
        $kfonction =~ s/[^a-zéàè]+/ /gi;
        $fonction2inter{$kfonction} = $intervenant;
    } elsif ($fonction =~ /[,\s]*suppléant[^,]*,\s*/i) {
        $kfonction = $fonction;
        $kfonction =~ s/[,\s]*suppléant[^,]*,\s*//i;
        $kfonction =~ s/[^a-zéàè]+/ /gi;
        $fonction2inter{$kfonction} = $intervenant;
    }
    #print "$fonction ($kfonction)  => $intervenant-".$inter2fonction{$intervenant}."\n";
    if (!$inter2fonction{$intervenant} || length($inter2fonction{$intervenant}) < length($fonction)) {
	$inter2fonction{$intervenant} = $fonction;
    }
    if ($intervenant =~ / et / && $kfonction =~ s/s$//) {
	$intervenants = $intervenant;
	$intervenants =~ s/ et .*//;
	setFonction($kfonction, $intervenants);
    }
    return $intervenant;
}

sub setIntervenant {
    my $intervenant = shift;
    $intervenant =~ s/<[^>]+>\s*//g;
    $intervenant =~ s/<[^>]*$//;
    #print "TEST $intervenant\n";
    $intervenant =~ s/^.* de (M(\.|me) )/\1/;
    $intervenant =~ s/president/président/gi;
    $intervenant =~ s/ présidence / présidente /;
    $intervenant =~ s/Erika Bareigts/Ericka Bareigts/g;
    $intervenant =~ s/Joachim Pueyo/Joaquim Pueyo/g;
    $intervenant =~ s/\s*\&\#821[12]\;\s*//;
    $intervenant =~ s/^audition de //i;
    $intervenant =~ s/^(M(\.|me))(\S)/$1 $3/;
    $intervenant =~ s/\.\s*[\/\|]\s*/, /g;
    $intervenant =~ s/[\|\/\.]//g;
    $intervenant =~ s/\s*[\.\:]\s*$//;
    $intervenant =~ s/Madame/Mme/;
    $intervenant =~ s/Monsieur/M./;
    $intervenant =~ s/et M\. /et M /;
    $intervenant =~ s/^M[\.mes]*\s//i;
    $intervenant =~ s/\s*\..*$//;
    $intervenant =~ s/L([ea])\s/l$1 /i;
    $intervenant =~ s/\s+\(/, /g;
    $intervenant =~ s/\)//g;
    $intervenant =~ s/[\.\,\s]+$//;
    $intervenant =~ s/^\s+//;
    $intervenant =~ s/É+/é/gi;
    $intervenant =~ s/\&\#8217\;/'/g;
    $intervenant =~ s/^(l[ea] )?d..?put..?e?\s+//i;
    $intervenant =~ s/^(l[ea] )?(s..?nat(eur|rice))\s+(.*)$/\4, \2/i;
    $intervenant =~ s/^l[ea] ((co[-\s]*|vice[-\s]*)?présidente?|rapporteure?|[Mm]inistre) (M(\.|me)?\s)?([A-ZÉÈÊÀÂÔÙÛÎÏÇ].*)$/\5, \1/;
    $intervenant =~ s/([A-ZÉÈÊÀÂÔÙÛÎÏÇ][^,\s]+) ([Rr]apporteur|[Pp]résident)/\1, \2/;
    #print "TEST2 $intervenant\n";
    if ($intervenant =~ s/\, (.*)//) {
	setFonction($1, $intervenant);
    }
    if ($intervenant =~ s/^([A-ZÉÈÊÀÂÔÙÛÎÏÇ].+) ?([Ll][ea] )?((([Pp]résident|[Rr]apporteur)[es,\st]*)+)$/\1/) {
        return setFonction($3, $intervenant);
    }
    if ($intervenant =~ /^[a-z]/) {
	$intervenant =~ s/^l[ea]\s+//i;
	if ($intervenant =~ /((([pP]résident|[rR]apporteur[a-zé\s]+)[\sest,]*)+)([A-ZÉÈÊÀÂÔÙÛÎÏÇ].*)/) {
        $tmpint = $4;
        $tmpfct = $1;
        if ($tmpint != "éral") {
        if ($tmpint =~ /commission/i || $tmpfct =~ /commission d['esla\s]+$/i) {
            $tmint = setFonction("$tmpfct $tmpint");
            if ($tmint) {
                return $tmint;
            }
        } else {
	        return setFonction($tmpfct, $tmpint);
	    }
        }
    }
	$conv = $fonction2inter{$intervenant};
    $maybe_inter = "";
	#print "TEST conv: '$conv' '$intervenant'\n";
	if ($conv) {
	    $intervenant = $conv;
	}else {
	    $test = lc($intervenant);
        $ktest = $test;
	    $ktest =~ s/[^a-zéàè]+/ /gi;
	    foreach $fonction (keys %fonction2inter) { if ($fonction2inter{$fonction}) {
		if ($fonction =~ /$ktest/i) {
            if ($fonction !~ /délégué/i || $test =~ /délégué/i) {
		        $inter = $fonction2inter{$fonction};
                $maybe_inter = "";
		        last;
            } elsif (!$maybe_inter || ($test =~ /délégué/i && $fonction =~ /délégué/i) || ($test !~ /délégué/i && $fonction !~ /délégué/i)) {
                $maybe_inter = $fonction2inter{$fonction};
            }
		}
	    } }
        if ($maybe_inter) {
            $inter = $maybe_inter;
        }
	    if (!$inter) {
		foreach $fonction (keys %fonction2inter) { if ($fonction2inter{$fonction}) {
            $kfonction = lc($fonction);
            $kfonction =~ s/ +/.+/g;
		    if ($test =~ /$kfonction/i) {
			$inter = $fonction2inter{$fonction};
			last;
		    }
		} }
	    }
	    if ($inter) {
		$intervenant = $inter;
	    }
	}
    }
    return $intervenant;
}

sub rapporteur
{
    #Si le commentaire contient peu nous aider à identifier le rapport, on tente
    if ($line =~ /rapport/i) {
	if ($line =~ /M[me\.]+\s([^,()]+), (rapporteur[^\)\,\.\;]*)/i) {
        $fct = $2;
        $fct =~ s/\s+et\s+.*$//;
	    setFonction($fct, $1);
	}elsif ($line =~ /rapport de \|?M[me\.]+\s([^,\.\;\|]+)[\,\.\;\|]/i) {
	    setFonction('rapporteur', $1);
	}
    } elsif ($line =~ /ministre/i) {
        $line =~ s/[\r\n]//g;
        @pieces = split(/(,|et) de M[mes\.]+ /, $line);
        foreach $l (@pieces) {
            $l =~ s/, sur .*$//;
            if ($l ne $line && $l !~ /^[\/\|]?l[ea]s? /i && $l =~ /(M[me\.]+\s)?([^,]+), ([Mm]inistre ((, |et |([dl][eaus'\s]+))*(\S+(\s+|$)){1,4})+)/) {
                setFonction($3, $2);
            }
        }
    }
}

$string =~ s/\r//g;
$string =~ s/&#8217;/'/g;
$string =~ s/d\W+évaluation/d'évaluation/g;
$string =~ s/&#339;|œ+/oe/g;
$string =~ s/\|(\W+)\|/$1/g;
$string =~ s/ission d\W+information/ission d'information/gi;
$string =~ s/à l\W+aménagement /à l'aménagement /gi;
$majIntervenant = 0;
$body = 0;

$string =~ s/<br>\n//gi;
$string =~ s/\s*<\/h(\d+)><\/CRPRESIDENT><CRPRESIDENT><h\1[^>]*>\s*/ /gi;
$string =~ s/(<\/h\d+>)/\1\n/gi;
$string =~ s/<t([rdh])[^>]*( (row|col)span=["\d]+)+[^>]*>/<t\1\2>/gi;
$string =~ s/<t([rdh])( (row|col)span=["\d]+)*[^>]*>/<t\1\2>/gi;
$string =~ s/\n+\s*(<\/?t(able|[rdh]))/\1/gi;
$string =~ s/(<\/table>)\s*(<table)/\1\n\2/gi;
$string =~ s/(<img[^>]*)[\n\r]+([^>]*>)/\1 \2/gi;
$string =~ s/-->(-->)+/-->/g;
#$string =~ s/<!-- \.(.*?)\. -->//g;

# Le cas de <ul> qui peut faire confondre une nomination à une intervention :
#on vire les paragraphes contenus et on didascalise
$string =~ s/<\/?ul>//gi;

#print $string; exit;

foreach $line (split /\n/, $string)
{
#print "TEST: ".$line."\n";
    $line =~ s/residen/résiden/ig;
    if ($line =~ /<h[1-9]+/i || $line =~ /"présidence"/ || $line =~ /Présidence de/) {
      if ($line =~ /pr..?sidence\s+de\s+(M[^<\,]+?)[<,]/i && $line !~ /sarkozy/i) {
        $prez = $1;
        $prez =~ s/\s*pr..?sident[es\s]*$//i;
#       print "Présidence de $prez\n";
        if ($prez =~ /^Mm/) {
          setFonction('présidente', $prez);
        }else {
          setFonction('président', $prez);
        }
      }
    }
    if ($line =~ /<body[^>]*>/) {
	$body = 1;
    }
    if ($line =~ /<meta /) {
        if($line =~ /name="NOMCOMMISSION" CONTENT="([^"]+)"/i) {
            $commission_meta = $1;
        }
    }
    next unless ($body);
    if ($line =~ /fpfp/) {
	checkout();
	next;
    }
    if ($line =~ /\<[a]/i) {
	if ($line =~ /<a name=["']([^"']+)["']/) {
	    $source = $url."#$1";
	}elsif($line =~ /class="menu"/ && $line =~ /<a[^>]+>([^<]+)<?/) {
	    $test = $1;
	    if (!$commission && $test =~ /Commission|mission/) {
		$test =~ s/\s*Les comptes rendus de la //;
		$test =~ s/^ +//;
		if ($test !~ /(spéciale|enquête)$/i) {
			$commission = $test;
		}
	    }
	}
    }
    if ($line =~ /<h[1-9]+/i) {
        rapporteur();
       #print "$line\n";
        if (!$date && $line =~ /SOM(seance|date)|\"seance\"|h2/) {
            if ($line =~ /SOMdate|Lundi|Mardi|Mercredi|Jeudi|Vendredi|Samedi|Dimanche/i) {
              if ($line =~ /(\w+\s+)?(\d+)[erme]*\s+([^\s\d()!<>]+)\s+(\d\d+)/i) {
                $date = sprintf("%04d-%02d-%02d", $4, $mois{lc($3)}, $2);
              }
            }
        }elsif ($line =~ /SOMseance|"souligne_cra"/i) {
            if ($line =~ /(\d+)\s*(h(?:eures?)?)\s*(\d*)/i) {
                $heure = sprintf("%02d:%02d", $1, $3 || "00");
            }
        }elsif(!$commission && $line =~ /groupe|commission|mission|délégation|office|comité/i) {
            if ($line =~ /[\>\|]\s*((Groupe|Com|Miss|Délé|Offic)[^\>\|]+)[\<\|]/) {
                $commission = $1;
                $commission =~ s/\s*$//;
            }
        }elsif($line =~ /SOMnumcr/i) {
            if ($line =~ /\s0*(\d+)/ && $1 > 1) {
                $cpt = $1*1000000;
            }
        }
    }

    if ($prez && $line =~ /<\/?t(able|d|h|r)/) {
        $line =~ s/([^<])[\/\|]/\1/g;
        $line =~ s/<[^t\/][^>]*>//g;
        $line =~ s/<\/[^t][^>]*>//g;
        checkout() if ($intervenant || ($line =~ /<table/ && length($intervention) + length($line) gt 2000));
        $intervention .= "$line";
    }elsif ($line =~ /\<p/i || ($line =~ /(<SOMMAIRE>|\<h[1-9]+ class="titre\d+)/i && $line !~ />Commission/)) {
	$found = 0;
    $line =~ s/<\/?SOMMAIRE>/\//g;
    while ($line =~ /^(.*)<(img.*? src=.)(.*?)(['"][^\>]+)>(.*)$/i) {
      $img0 = $1;
      $img1 = $2;
      $img2 = $4;
      $img3 = $5;
      $imgurl = $3;
      if ($imgurl =~ /^\//) {
        $imgurl = $rooturl.$imgurl
      } elsif ($imgurl !~ /^http/i) {
        $imgurl = $baseurl.$imgurl;
      }
      $imgurl =~ s/[\/]/\\\\/g;
      $img2 =~ s/[\\]/\\\\/g;
      $line = $img0."##".$img1.$imgurl.$img2."##".$img3;
    }
	$line =~ s/\<\/?[^\>]+\>//g;
    $line =~ s/\s+/ /g;
    $line =~ s/^\s//;
    $line =~ s/\s$//;
    $line =~ s/\s*,\s*\|\s*\/\s*/,|\/ /g;
    $line =~ s/\s*\|\s*,\s*\/\s*/,|\/ /g;
    $line =~ s/\|\|//g;
    $line =~ s/\/\///g;
	$line =~ s/##(img[^\>#]+?)##/<\1 \\\\>/ig;
	last if ($line =~ /^\|annexe/i);
	next if ($line !~ /\w/);
    $tmpinter = "";
    #print STDERR $line."\n";
	#si italique ou tout gras => commentaire
	if (($line =~ /^\|.*\|\s*$/ || $line =~ /^\/.*\/\s*$/) && $line !~ /^\|Articles?\s*\d+/i) {
	    if (!$timestamp && !$commission && $line =~ /^\|(.*(groupe|mission|délégation|office|comité).*)\|\s*$/i) {
		$commission = $1;
		next;
	    }
        if ($intervenant) {
            if ($line =~ /^\/\(.*\.\)\/$/) {
                $tmpinter = $intervenant;
            }
            checkout();
        }
	    rapporteur();
	    $found = 1;
	}
#print "LINE: $line\n";
    if ($line =~ s/^\|(M[^\|\:]+?)(?:[\|\:](\/[^\/]+?\/)?|((?:, \/|\/, )[^\/]+?\/))(.*\w.*)/\4/) {
        checkout();
        $interv1 = $1;
	    $extrainterv = $2.$3;
        if ($extrainterv =~ s/(\/A \w+i\/)//) {
            $line = $1.$line;
        }
        $intervenant = setIntervenant($interv1.$extrainterv);
        $found = $majIntervenant = 1;
	}elsif (!($line =~ /^\|(?:Commission|Présidence|Titre|Chapitre|Section|Articles?)/i) && ($line =~ s/^\|([^\|,]+)\s*,\s*([^\|]+)\|// || $line =~ s/^(M(?:me|\.)\s[^\/,]+)(?:\/\s*,|,\s*\/)[\/,\s]*([^\.]+)[\.][\/\s]*//)) {
        checkout();
        $found = $majIntervenant = 1;
	    $intervenant = setFonction($2, $1);
	}elsif ($line =~ s/^[Llea\s]*\|[Llea\s]*([pP]r..?sidente?) (([A-ZÉ][^\.: \|]+ ?)+)[\.: \|]*//) {
		$f = $1;
		$i = $2;
		$found = $majIntervenant = 1;
        checkout();
        $intervenant = setFonction($f, $i);
	}elsif ($line =~ s/^[Llea\s]*\|[Llea\s]*([pP]r..?sidente?|[rR]apporteure?)[\.: \|]*//) {
		$tmpfonction = lc($1);
		$tmpintervenant = $fonction2inter{$tmpfonction};
		if ($tmpintervenant) {
	                checkout();
			$intervenant = $tmpintervenant;
			$found = $majIntervenant = 1;
		}
	}
	$line =~ s/^\s+//;
	$line =~ s/[\|\/]//g;
	$line =~ s/^[\.\:]\s*//;
    #print STDERR $line."\n";
	if (!$found && $line !~ /^\s*M(mes?|[e\.])\s+[^\.:]*(interroge|question|soulève)/) {
	    if ($line =~ s/^\s*((Dr|Ingénieur|(Géné|Ami|Capo)ral|M(mes?|[e\.]))(\s([dl][eaus'\s]+)*[^\.:\s]{2,}){1,4})[\.:]//) {
            checkout();
            $intervenant = setIntervenant($1);
	    }elsif (!$majIntervenant) {
            if ($line =~ s/^\s*(M(mes?|[e\.])\s[A-Z][^\s\,]+\s*([A-Z][^\s\,]+\s*|de\s*){2,})// ) {
        	    checkout();
    	        $intervenant = setIntervenant($1);
            }elsif($line =~ s/^\s*[Ll][ea] ([pP]r[ée]sidente?) (([A-ZÉ][^\.: \|]+ ?)+)[\.: \|]*//) {
                setFonction($1, $2);
                checkout();
                $intervenant = setIntervenant($2);
            }
	    }
	}
    if ($line) {
	  $intervention .= "<p>$line</p>";
    }
    }
    if (length($intervention)-32000 > 0) {
        $tmpinter = $intervenant;
        checkout();
    }
    if ($tmpinter) {
        checkout();
        $intervenant = $tmpinter;
    }
    if ($line =~ /séance est levée/i) {
        last;
    }
}
checkout();
