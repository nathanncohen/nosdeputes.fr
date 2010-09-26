<div class="precedent"><?php echo myTools::displayDate($doc->date); ?></div>
<div class="source"><?php if ($section) echo link_to('Dossier relatif', '@section?id='.$section->id); else echo '<a href="http://www.assemblee-nationale.fr/13/dossiers/'.$doc->url_an.'.asp">Dossier sur le site de l\'Assemblée</a>'; ?></div>
<h1><?php echo $doc->getShortTitre(); ?></h1>
<h2><?php echo preg_replace('/ - /', '<br/>- ', $doc->getDetailsTitre()); ?></h2>
<div class="document">
<?php $feminin = "";
if (preg_match('/(propos|lettre)/i', $doc->type))
  $feminin = "e";

if ($auteurs) {
  echo '<div class="photos"><h3 class="aligncenter">écrit'.$feminin." par ";
  include_partial('parlementaire/auteurs', array("deputes" => $auteurs, "orga" => $orga));
  include_partial('parlementaire/photos', array("deputes" => $auteurs));
  echo '</p></div>';
} else if ($orga->id) {
  echo '<h3 class="aligncenter">';
  if ($orga && $orga->type != "groupe") echo link_to($orga->nom, "@list_parlementaires_organisme?slug=".$orga->slug);
  else if ($orga) echo link_to($orga->nom, "@list_parlementaires_groupe?acro=".$orga->getSmallNomGroupe());
  else echo $doc->getAuteursString();
  echo '</h3>';
} else echo '<h3 class="aligncenter">'.$doc->getSignatairesString().'</h3>';
if ($cosign) {
  echo '<div class="photos"><p class="aligncenter">cosigné'.$feminin." par ";
  include_partial('parlementaire/auteurs', array("deputes" => $cosign));
  include_partial('parlementaire/photos', array("deputes" => $cosign));
  echo '</p></div>';
}

?>
</div>
<div class="document">
<div class="left">
<?php if ($txt = $doc->getExtract()) { ?>
<h3>Extrait</h3>
<p class="justify tabulation"><?php echo preg_replace('/([a-z])\. ([^"»])/', '\\1.</p><p class="justify tabulation">\\2', $doc->getExtract()); ?></p>
<?php } ?>
<h3><a href="<?php echo $doc->source; ?>">Consulter le document complet sur le site de l'Assemblée</a></h3>
<p class="aligncenter">(<?php echo link_to('version pdf', preg_replace('/asp$/', 'pdf', preg_replace('/13\//', '13/pdf/', $doc->source))); ?>)</p>
</div>
<div class="right">
<div class="nuage_de_tags">
<h3>Mots-clés</h3>
  <?php echo include_component('tag', 'tagcloud', array('tagquery' => $qtag, 'model' => 'Texteloi', 'limit' => 40, 'fixlevel' => 1)); ?>
</div>
<?php if ((isset($texte) && $texte > 0) || count($annexes) || $amendements) { ?>
  <div class="annexes">
  <h3>Documents associés</h3><ul>
  <?php if ($amendements) echo '<li>'.link_to("Voir les ".$amendements." amendement".($amendements > 1 ? "s" : "")." déposé".($amendements > 1 ? "s" : "")." sur ce texte", '@find_amendements_by_loi_and_numero?loi='.$doc->numero.'&numero=all').'</li>';
  if (isset($texte) && $texte > 0)
    echo '<li>'.link_to('Voir le rapport de la commission', '@document?id='.$doc->numero).'</li>';
  if (count($annexes)) {
    foreach ($annexes as $annexe) if ($annexe['id'] != $doc->id && preg_match('/-a0/', $annexe['id']))
      echo '<li>'.link_to('Voir le texte adopté par la commission', '@document?id='.$doc->numero.'-a0').'</li>';
    foreach ($annexes as $annexe) if ($annexe['id'] != $doc->id && preg_match('/t([\dIVX]+)/', $annexe['id'], $tom)) {
      $titreannexe = "Tome&nbsp;".$tom[1];
      if (preg_match('/v(\d+)/', $annexe['id'], $vol))
        $titreannexe .= " - volume ".$vol[1];
      echo '<li>'.link_to($titreannexe, '@document?id='.$annexe['id']).'</li>';
    }
    foreach ($annexes as $annexe) if ($annexe['id'] != $doc->id && preg_match('/-a([1-9]\d*)/', $annexe['id'], $ann))
      echo '<li>'.link_to("Annexe N°&nbsp;".$ann[1], '@document?id='.$annexe['id']).'</li>';
  } 
  echo '</ul></div>';
} ?>
</div>
</div>
<div class="commentaires document">
<?php if ($doc->nb_commentaires == 0)
  echo '<h3 class="list_com">Aucun commentaire n\'a encore été formulé sur '.$doc->getTypeString().'</h3>';
else echo include_component('commentaire', 'showAll', array('object' => $doc));
echo include_component('commentaire', 'form', array('object' => $doc)); ?>
</div>
