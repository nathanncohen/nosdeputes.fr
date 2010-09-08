<?php
/**
 * This class has been auto-generated by the Doctrine ORM Framework
 */
class OrganismeTable extends Doctrine_Table
{
  public function findOneByNomType($nom, $type) {
    $nom = self::cleanNom($nom);

    if ($option = Doctrine::getTable('VariableGlobale')->findOneByChamp('commissions')) {
      $commissions = unserialize($option->getValue());
      if (isset($commissions[$nom]) && $org = $this->findOneByNom($commissions[$nom]))
        return $org;
    }

    if ($type == 'parlementaire')
    $org = $this->createQuery('o')
      ->where('o.nom LIKE ?', $nom.'%')
      ->orderBy('LENGTH(o.nom) DESC')
      ->fetchOne();
    if ($type != 'parlementaire' || strlen($org->nom) < 50)
      $org = $this->findOneByNom($nom);

    if ($org) {
      //      echo $org->nom."- $nom (trouve)\n";

      if (strlen($nom) > strlen($org->nom)) {
	$org->nom = $nom;
	$org->save();
      }
      return $org;
    }
//        echo "- $nom (pas trouve)\n";
    

    $orgs = Doctrine::getTable('Organisme')->createQuery('o')->where('type = ?', $type)->execute();
    foreach($orgs as $o) {
      $res = similar_text($o->nom, $nom, $pc);
      if ($pc > 95) {
//		  echo "$nom $pc\n".$o->nom."\n";
	$org = $o;
	break;
      }
    }
    if ($org)
      return $org;
    return null;
  }
 
  public function findOneByNomOrCreateIt($nom, $type) {
    $org = $this->findOneByNomType($nom, $type);
    if ($org)
      return $org;
    $org = new Organisme();
    $org->type = $type;
    $org->nom = self::cleanNom($nom);
    $org->save();
    return $org;
  }
  
  private static function cleanNom($nom) {
    $nom = strtolower($nom);
    $nom = preg_replace('/(&#8217;|\')/', '’', $nom);
    $nom = preg_replace('/\W+$/', '', $nom);
    $nom = preg_replace('/\([^\)]*\)/', '', $nom);
    $nom = preg_replace('/\([^\)]*$/', '', $nom);
    $nom = preg_replace('/^[^\)]*\)/', '', $nom);
    $nom = preg_replace('/’/', '\'', $nom);
    $nom = preg_replace('/^\s*assemblée\s+nationale\s*$/i', 'bureau de l\'assemblée nationale', $nom);
    trim($nom);
    $nom = preg_replace('/^\s*de la /', '', $nom);
    $nom = preg_replace('/\s+/', ' ', $nom);
    return $nom;
  }
}
