<div align="center">

<sub>🧩 <b>Suite Pure</b> &nbsp;·&nbsp; <a href="https://github.com/ma3iich/pure-target">Pure-Target</a> (menu clic droit) &nbsp;·&nbsp; <b>Pure Inventory</b> (inventaire) &nbsp;—&nbsp; chacun marche seul, et ils marchent ensemble</sub>

[![English](https://img.shields.io/badge/Language-English-555)](README.md) [![Français](https://img.shields.io/badge/Langue-Fran%C3%A7ais-2ea44f)](README.fr.md)

<img src="docs/banner.png" alt="Pure Inventory — l'inventaire FiveM avec ton perso en 3D" width="100%">
<br>

**Un inventaire à cases pour FiveM avec ton personnage en 3D, des cases de vêtements et un rendu réglable dans un seul fichier.**<br>
Standalone, ou prêt à l'emploi avec QBCore. Fork d'`ox_inventory` : tous les scripts faits pour `ox_inventory` continuent de marcher.

[![FiveM](https://img.shields.io/badge/FiveM-resource-F26722?logo=fivem&logoColor=white)](https://fivem.net)
[![Lua](https://img.shields.io/badge/Lua-5.4-2C2D72?logo=lua&logoColor=white)](https://www.lua.org)
[![Standalone](https://img.shields.io/badge/framework-standalone%20%7C%20QBCore-6e7681)](#-installation)
[![Licence](https://img.shields.io/badge/licence-GPL--3.0-3fb950)](LICENSE)

**[⬇️ Télécharger](https://github.com/ma3iich/pure_inventory/releases/latest)** &nbsp;·&nbsp;
**[📦 Installation](#-installation)** &nbsp;·&nbsp;
**[⚙️ Configuration](#%EF%B8%8F-configuration)** &nbsp;·&nbsp;
**[🗄️ SQL](sql/README.md)** &nbsp;·&nbsp;
**[❓ FAQ](#-faq)**

<sub>Fork d'<a href="https://github.com/overextended/ox_inventory">ox_inventory</a> par Overextended (version QBCore maintenue par <a href="https://github.com/TheOrderFivem/ox_inventory">TheOrderFivem</a>) · Fait par <a href="https://github.com/ma3iich">ma3iich</a></sub>

<img src="docs/preview.jpg" alt="Pure Inventory" width="100%">

</div>

---

## 🎬 Aperçus

<table>
  <tr>
    <th width="33%">🖱️ Glisser-déposer</th>
    <th width="33%">👕 Cases de vêtements</th>
    <th width="33%">🍔 Utiliser sur ton perso</th>
  </tr>
  <tr>
    <td><video src="https://github.com/user-attachments/assets/6e9ac890-b6db-4870-b305-758e6a581e72" width="100%" controls muted></video></td>
    <td><video src="https://github.com/user-attachments/assets/6cd18932-d0d6-4f7c-8e42-12e1e3ea58dd" width="100%" controls muted></video></td>
    <td><video src="https://github.com/user-attachments/assets/6b5c38c5-7e68-41d4-b09f-20e5dd7282af" width="100%" controls muted></video></td>
  </tr>
  <tr>
    <th>🧍 Perso 3D</th>
    <th>🔢 Quantité</th>
    <th>⌨️ Tes propres touches</th>
  </tr>
  <tr>
    <td><video src="https://github.com/user-attachments/assets/8f959996-75ed-436c-80b7-85f4c70e5fc6" width="100%" controls muted></video></td>
    <td><video src="https://github.com/user-attachments/assets/07240999-15d9-42c6-90ff-a85b6c3d3f21" width="100%" controls muted></video></td>
    <td><video src="https://github.com/user-attachments/assets/1460e671-0f3c-4d78-81a8-284b044cf568" width="100%" controls muted></video></td>
  </tr>
</table>

---

## ✨ Fonctionnalités

<table>
  <tr>
    <td width="50%">🧍 <b>Ton personnage en 3D</b><br><sub>Au milieu de l'inventaire. Clic gauche maintenu pour le tourner, molette pour zoomer. Il reste immobile à l'écran même quand tu marches ou conduis.</sub></td>
    <td width="50%">👕 <b>Cases de vêtements</b><br><sub>Clique sur un vêtement porté (ou glisse-le dans l'inventaire) pour l'enlever : il devient un objet. Glisse-le sur ton personnage pour le remettre.</sub></td>
  </tr>
  <tr>
    <td>🎨 <b>Ton rendu dans un seul fichier</b><br><sub>Couleur et opacité des cases, taille, nombre de lignes, coins arrondis, police, couleurs du menu, icônes des vêtements : tout est dans <code>config.lua</code>.</sub></td>
    <td>🖱️ <b>Glisser-déposer partout</b><br><sub>Un objet lâché sur ton personnage est utilisé, sur une case de vêtement il est enfilé, un vêtement porté va dans la case de ton choix.</sub></td>
  </tr>
  <tr>
    <td>✏️ <b>Renommer dans la case</b><br><sub>Clic droit &gt; Renommer, tape le nouveau nom directement dans la case. Entrée pour enregistrer, Échap pour annuler.</sub></td>
    <td>🚶 <b>Reste ouvert</b><br><sub>Marche inventaire ouvert ; il reste ouvert quand tu manges, bois, te soignes, changes de vêtement, ou pendant une barre de chargement.</sub></td>
  </tr>
  <tr>
    <td>🔌 <b>Standalone ou QBCore</b><br><sub>Détecte ton framework tout seul (QBCore, Qbox, ESX, ox_core, ND), ou fonctionne sans framework.</sub></td>
    <td>🔒 <b>Serveur renforcé</b><br><sub>Contrôles serveur en plus sur chaque déplacement, dépôt, don, fabrication, achat et action d'arme (voir <a href="#-différences-avec-ox_inventory">différences</a>).</sub></td>
  </tr>
</table>

Plus de 13 langues : English, Français, Deutsch, Español, Italiano, Português, Nederlands, Polski, Türkçe, Русский, 中文, 日本語, 한국어 (+ celles d'ox_inventory).

---

## 📋 Dépendances

| Ressource | Obligatoire | Remarques |
| --- | --- | --- |
| [oxmysql](https://github.com/overextended/oxmysql) | ✅ | 2.7.3 ou plus récent |
| [ox_lib](https://github.com/overextended/ox_lib) | ✅ | 3.27.0 ou plus récent (ox_lib 3.41+ a aussi besoin de `cfxlua-require`, fourni dans son zip) |
| Serveur FiveM | ✅ | artifact 6116 ou plus récent, **OneSync** activé |
| qb-core / qbx_core / es_extended / ox_core / ND_Core | facultatif | sans framework : mode standalone |
| ox_target ou [pure-target](https://github.com/ma3iich/pure-target) | facultatif | seulement avec `Config.Target = true` |
| progressbar (QBCore) | facultatif | l'inventaire reste ouvert pendant ses barres de chargement |
| un script d'apparence (illenium-appearance, qb-clothing...) | facultatif | les cases de vêtements marchent avec n'importe lequel |

---

## 📦 Installation

1. Télécharge la [dernière version](https://github.com/ma3iich/pure_inventory/releases/latest) et mets le dossier `pure_inventory` dans tes `resources`.
2. **Retire `ox_inventory` et `qb-inventory`** (Pure Inventory les remplace : jamais deux inventaires en même temps).
3. Dans `server.cfg`, après `oxmysql`, `ox_lib` et ton framework :
   ```cfg
   ensure oxmysql
   ensure ox_lib
   ensure qb-core          # si tu utilises QBCore
   ensure pure_inventory
   ```
4. Démarre le serveur : les tables se créent toutes seules ([fichiers SQL](sql/README.md) si tu préfères les lancer toi-même).
5. Facultatif : ouvre `config.lua` et règle la langue, les cases et le rendu.

**QBCore :** rien d'autre à faire. Au premier démarrage, les objets de QBCore sont recopiés dans `data/items.lua` (redémarre une fois, comme ox_inventory).
`exports['qb-inventory']` (AddItem, RemoveItem, HasItem...) et les fonctions joueur de QBCore continuent de marcher.

**Standalone :** les joueurs sont enregistrés par leur licence FiveM. Les métiers (police...) viennent des permissions ACE :
```cfg
add_ace group.police pure_inventory.group.police allow
add_principal identifier.license:xxxxxxxx group.police
```

**Tu viens d'ox_inventory :** tes données restent (mêmes tables, même format de `data/*.lua` : recopie tes objets, magasins, coffres...).
Les `exports.ox_inventory:...` de tes autres scripts marchent, et `GetResourceState('ox_inventory')` répond `started`.

---

## ⚙️ Configuration

Tout est dans **`config.lua`**, avec un commentaire sur chaque ligne. Les grandes parties :

| Partie | Ce que tu règles |
| --- | --- |
| Général | framework (`auto`), langue |
| Inventaire du joueur | cases, poids, touches, métiers de police |
| Comportement | reste ouvert quand on utilise un objet (et les objets qui le ferment quand même), marcher inventaire ouvert, flou, renommer |
| Rendu (`Config.Theme`) | couleur **et opacité** des cases, opacité au survol, liseré, taille, espace, colonnes, lignes visibles, coins arrondis, bande du nom, couleur du texte, majuscules, police, couleurs du menu, taille / couleur des icônes / couleurs des cadenas des cases de vêtements |
| Personnage 3D | position, taille, pose, lumière, zoom |
| Cases de vêtements | quelles cases, de quel côté, **leur icône** (intégrée ou ton image), poids, valeurs « nu », animations |
| Standalone | identifiant, groupes ACE, durée de conservation des coffres |
| Avancé | les options d'origine d'ox_inventory |

Une convar `inventory:<nom>` (ox.cfg d'ox_inventory) remplace toujours le réglage correspondant.
Ton webhook Discord reste dans `server.cfg` (`set inventory:webhook "..."`) : jamais dans `config.lua`, qui est envoyé aux joueurs.

Objets, magasins, coffres, établis et coffres de véhicules sont dans `data/` exactement comme ox_inventory
([documentation](https://coxdocs.dev/ox_inventory)).

---

## 👕 Comment marchent les cases de vêtements

- Chaque case est un composant ou un accessoire de GTA (`Config.Clothing.Slots`). Vêtement porté = cadenas vert, retiré = cadenas rouge.
- Enlever un vêtement donne un objet `clothing` qui retient le modèle, le dessin et la texture. Il ne va qu'aux personnages du même modèle (homme / femme freemode).
- Ce qu'un personnage a enlevé est enregistré (`pure_inventory_clothing`) : quand ton script d'apparence rhabille le personnage après une reconnexion, les vêtements enlevés sont retirés de nouveau. Un vêtement ne peut donc jamais devenir deux objets.
- Changer de vêtements dans un magasin de vêtements reprend simplement la main : le magasin décide pour les pièces changées.
- Seuls les personnages freemode (`mp_m_freemode_01` / `mp_f_freemode_01`) ont des cases de vêtements.
- Limite de GTA : les gants font partie du composant « bras », dont la forme dépend du haut. Enlever le haut dénude aussi les bras ; ils reviennent avec le haut.

---

## ❓ FAQ

<details><summary><b>Un script dit qu'il lui faut ox_inventory</b></summary>
Pure Inventory déclare <code>provide 'ox_inventory'</code> et répond à <code>exports.ox_inventory</code>. Si un script cherche encore le nom du dossier, renomme le dossier <code>pure_inventory</code> en <code>ox_inventory</code> : tout marche sous les deux noms.
</details>

<details><summary><b>Les images d'objets d'autres scripts n'apparaissent pas</b></summary>
Les scripts qui affichent les images avec l'adresse <code>nui://ox_inventory/web/images/...</code> ont besoin de <code>nui://pure_inventory/web/images/...</code> (ou renomme le dossier en <code>ox_inventory</code>).
</details>

<details><summary><b>Je ne veux pas le personnage 3D / les cases de vêtements</b></summary>
<code>Config.PedPreview.Enabled = false</code> et / ou <code>Config.Clothing.Enabled = false</code>.
</details>

<details><summary><b>Comment changer l'icône d'une case de vêtement ?</b></summary>
Dans <code>Config.Clothing.Slots</code>, mets dans <code>icon</code> un autre nom d'icône intégrée ou ta propre image : <code>icon = 'nui://ma_ressource/icones/chapeau.png'</code>. L'image des objets vêtements est <code>web/images/clothing_&lt;case&gt;.png</code>.
</details>

<details><summary><b>Où signaler un bug ?</b></summary>
Viens sur le <a href="https://discord.gg/C4jc8k3dD9">Discord</a> et ouvre un ticket, avec la console du serveur et la console F8.
</details>

---

## 🔁 Différences avec ox_inventory

Pure Inventory part d'**ox_inventory 2.45.1** (fork TheOrderFivem, le dernier qui gère QBCore). Principaux changements :

- **Nouveau :** personnage 3D, cases de vêtements, renommer dans la case, nouveau rendu piloté par `config.lua`, compteur de quantité (× / ›), anneau de poids, mode standalone, détection automatique du framework, `config.lua` au lieu des convars, japonais + nouveaux textes en 13 langues.
- **Comportement :** reste ouvert quand on utilise un objet / pendant les barres de chargement ox_lib et QBCore, marcher inventaire ouvert, se ferme quand une autre fenêtre prend le clavier, objets à lancer repris en main l'un après l'autre, animations chargées avant la barre, objets qui s'usent qui quittent leur pile un par un, conteneurs vides empilables, conteneurs sans poids / imbriquables.
- **Sécurité (côté serveur) :** contrôles à chaque déplacement (toujours le droit d'utiliser l'autre inventaire : distance, plaque, verrou, droits de police / de vol), nombres entiers seulement, joueur menotté ou mort sans déplacement / utilisation / don, tas au sol limités et posés là où est le joueur, un joueur n'ouvre que SON coffre personnel, identifiant de coffre / boîte à gants tiré du véhicule, un client ne lit que son propre inventaire, fabrication impossible à sauter ou à lancer deux fois, achats revérifiés (métier, distance, quantité), actions d'arme vérifiées (munitions, accessoires, bidons), poubelles et casiers de preuves vérifiés par modèle / distance, « patron » = patron de CE métier.
- **Corrections :** la fouille d'un joueur ne ferme plus l'inventaire du fouilleur quand l'autre ouvre le sien, plaque exacte, armes avec un accessoire sans pièce GTA, armes en véhicule, `clearevidence` vide vraiment le casier, fichier de langue espagnol.

La liste complète est l'historique git de ce dépôt.

---

## 📜 Licence

Pure Inventory est une version modifiée d'ox_inventory, publiée sous **GNU GPL v3** comme l'original ([LICENSE](LICENSE)).
Copyright © 2026 ma3iich · basé sur ox_inventory, copyright © 2023 Overextended et contributeurs ([NOTICE](NOTICE.md)).
Les sources de l'interface sont dans `web/src` (`cd web && npm install && npm run build`).
