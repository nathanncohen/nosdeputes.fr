<?php

/**
 * This class has been auto-generated by the Doctrine ORM Framework
 */
class QuestionEcrite extends BaseQuestionEcrite
{

  public function getLink() {
    sfProjectConfiguration::getActive()->loadHelpers(array('Url'));
    return url_for('@question_numero?numero='.$this->numero);
  }
  public function getPersonne() {
    return $this->getParlementaire()->getNom();
  }

  public function __toString() {
    $str = substr(strip_tags($this->question), 0, 250);
    if (strlen($str) == 250) {
      $str .= '...';
    } else if (!$str) $str = "";
    return $str;
  }

  public function getTitre() {
    $titre = 'Question N° '.$this->numero.' du '.myTools::displayShortDate($this->date).' ('.preg_replace('/\s*[\/\(].*$/', '', $this->ministere).')';
    if ($this->date_cloture && !$this->reponse && date("Y-m-d") > $this->date_cloture) $titre .= ' (Retirée)';
    else if (!$this->reponse) $titre .= ' (Sans réponse)';
    return $titre;
  }

  public function setAuteur($depute) {
    $sexe = null;
    if (preg_match('/^\s*(M+[\s\.ml]{1})[a-z]*\s*([dA-Z].*)\s*$/', $depute, $match)) {
        $nom = $match[2];
        if (preg_match('/M[ml]/', $match[1]))
          $sexe = 'F';
        else $sexe = 'H';
    } else $nom = preg_replace("/^\s*(.*)\s*$/", "\\1", $depute);
    $depute = Doctrine::getTable('Parlementaire')->findOneByNomSexeGroupeCirco($nom, $sexe);
    if (!$depute) print "ERROR: Auteur introuvable in ".$this->source." : ".$nom." // ".$sexe."\n";
    else {
      $this->_set('Parlementaire', $depute);
      $depute->free();
    }
  }
  public function uniqueMinistere() 
  {
    $ministere = 'Ministère d';
    if (preg_match('/(Affaires|Espace)(\s+[\wàéëêèïîôöûüÉ]+)/', $this->ministere, $match)) $ministre = $match[1].$match[2];
    else {
      $ministre = preg_replace('/^.*\/\s*([\wàéëêèïîôöûüÉ]+)$/', '\\1', $this->ministere);
      $ministre = preg_replace('/^([\wàéëêèïîôöûüÉ]+)[,\s].*$/', '\\1', $ministre);
    }
    if (preg_match('/^(Affaires|Sports|Transports|Solidarités)/', $ministre)) $ministere .= 'es ';
    else if (preg_match('/^[AEÉIOU]/', $ministre)) $ministere .= 'e l\'';
    else if (preg_match('/^(Famille|Santé|Coopération|Culture|Défense|Justice|Consommation|Solidarité)/', $ministre)) $ministere .= 'e la ';
    else $ministere .= 'u ';
    if (preg_match('/^Premier/', $ministre)) $ministere = 'Premier Ministre';
    else $ministere .= $ministre;
    return $ministere;
  }
  public function firstTheme()
  {
    $theme = preg_replace('/^\s*([\w\-àéëêèïîôöûüÉ\s]+)*[,\/:].*$/', '\\1', $this->themes);
    $theme = preg_replace('/^(.*)\s+$/', '\\1', $theme);
    return $theme;
  }
}
