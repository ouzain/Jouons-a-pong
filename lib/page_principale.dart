import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'balle.dart';
import 'batte.dart';

// gérer les quatre directions possibles
enum Direction { haut, bas, gauche, droite }

class PagePrincipale extends StatefulWidget {
  const PagePrincipale({Key? key}) : super(key: key);

  @override
  State<PagePrincipale> createState() => _PagePrincipaleState();
}

class _PagePrincipaleState extends State<PagePrincipale>
    with SingleTickerProviderStateMixin {
  
  double largeur = 0;     
  double hauteur = 0;    

  
  double posX = 0;
  double posY = 0;

  // Dimensions et position de la batte
  double largeurBatte = 0;
  double hauteurBatte = 0;
  double positionBatte = 0;

  // Contrôleur et animation
  late Animation<double> animation;
  late AnimationController controleur;

  // Vitesse de déplacement de la balle
  double increment = 5;

  // la direction
  Direction hDir = Direction.gauche;  // direction horizontale
  Direction vDir = Direction.bas;     // verticale

  int score = 0;

  //  rendre la vitesse ou l’angle moins prévisible
  double randX = 1; 
  double randY = 1;

  @override
  void initState() {
    super.initState();
    // Initialisation de la position de la balle
    posX = 0;
    posY = 0;

    // Création du contrôleur d’animation
    // On choisit 10 000 minutes pour que l’animation tourne "indéfiniment"
    
    controleur = AnimationController(
      duration: const Duration(minutes: 10000),
      vsync: this,
    );

    // Création du Tween (0 à 100), mais on n’utilise que l’animation comme "tick"
    // pour appeler setState() et déplacer la balle manuellement.
    animation = Tween<double>(begin: 0, end: 100).animate(controleur);

    // On randomise la direction horizontale et verticale
    animation.addListener(() {
      safeSetState(() {
        // Déplacement horizontal
        if (hDir == Direction.droite) {
          posX += ((increment * randX).round());
        } else {
          posX -= ((increment * randX).round());
        }
        // Déplacement vertical
        if (vDir == Direction.bas) {
          posY += ((increment * randY).round());
        } else {
          posY -= ((increment * randY).round());
        }
      });
      // checker les collisions avec les bords ou la batte
      testerBordures();
    });

    // Lancement de l’animation
    controleur.forward();
  }

  @override
  void dispose() {
    // Libération des ressources du contrôleur
    controleur.dispose();
    super.dispose();
  }

  // Méthode sûre pour appeler setState() seulement si le widget est monté et que l’animation tourne
  void safeSetState(Function fonction) {
    if (mounted && controleur.isAnimating) {
      setState(() {
        fonction();
      });
    }
  }

  // déplacer la batte via le Drag horizontal
  void deplacerBatte(DragUpdateDetails maj, BuildContext context) {
    safeSetState(() {
      // Ajout du delta.x à la position de la batte
      positionBatte += maj.delta.dx;
      // empêcher la batte de sortir de l’écran 
      if (positionBatte < 0) {
        positionBatte = 0;
      }
      if (positionBatte + largeurBatte > largeur) {
        positionBatte = largeur - largeurBatte;
      }
    });
  }

  // gérer les rebonds et la fin de partie
  void testerBordures() {
    // Diamètre de la balle
    double diametreBalle = Balle.diametre;

    // 1) Rebond gauche
    if (posX <= 0) {
      posX = 0; 
      hDir = Direction.droite;
      // On randomise l’angle horizontal
      randX = nombreAleatoire();
    }
    // 2) Rebond droit
    if (posX >= largeur - diametreBalle) {
      posX = largeur - diametreBalle;
      hDir = Direction.gauche;
      // On randomise l’angle horizontal
      randX = nombreAleatoire();
    }
    // 3) Rebond en haut
    if (posY <= 0) {
      posY = 0;
      vDir = Direction.bas;
      // On randomise l’angle vertical
      randY = nombreAleatoire();
    }
    // 4) Rebond en bas => vérif si touche la batte ou non
    if (posY >= hauteur - diametreBalle) {
      // La balle arrive sur le bas. checker la position horizontale
      double centreBalle = posX + diametreBalle / 2;

      // Position de la batte [positionBatte .. (positionBatte+largeurBatte)]
      // La balle rebondit si son centre est dans cette zone
      if (centreBalle >= positionBatte &&
          centreBalle <= positionBatte + largeurBatte) {
        // Touché : on rebondit
        vDir = Direction.haut;
        posY = hauteur - diametreBalle;
        score++;
        // On randomise l’angle vertical
        randY = nombreAleatoire();
      } else {
        // Perdu : la balle est tombée en bas sans toucher la batte
        controleur.stop();
        afficherMessage(context);
      }
    }
  }

  // Popup de fin de partie
  void afficherMessage(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Perdu !'),
          content: Text('Votre score est : $score.\nVoulez-vous rejouer ?'),
          actions: [
            TextButton(
              onPressed: () {
                // Rejouer
                Navigator.of(ctx).pop(); // ferme la popup
                setState(() {
                  // Réinitialisation de la position et du score
                  score = 0;
                  posX = 0;
                  posY = 0;
                  hDir = Direction.gauche;
                  vDir = Direction.bas;
                });
                // On relance l’animation
                controleur.forward(from: 0.0);
              },
              child: const Text('OUI'),
            ),
            TextButton(
              onPressed: () {
                // Quitter
                Navigator.of(ctx).pop();   // ferme la popup
                // puis on arrête l’animation et on dispose
                controleur.dispose();
              },
              child: const Text('NON'),
            ),
          ],
        );
      },
    );
  }

  // Génère un nombre aléatoire entre 0.5 et 1.5
  double nombreAleatoire() {
    return (math.Random().nextInt(101) + 50) / 100;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints contraintes) {
        // On récupère la taille de la zone de jeu
        hauteur = contraintes.maxHeight;
        largeur = contraintes.maxWidth;

        // Mise à jour de la taille de la batte 
        largeurBatte = largeur / 5;
        hauteurBatte = hauteur / 20;

        return Stack(
          children: [
            // Score en haut à droite
            Positioned(
              top: 0,
              right: 24,
              child: Text(
                'Score : $score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Balle
            Positioned(
              top: posY,
              left: posX,
              child: const Balle(),
            ),

            // Batte
            Positioned(
              bottom: 0,
              left: positionBatte,
              child: GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails maj) =>
                    deplacerBatte(maj, context),
                child: Batte(
                  largeur: largeurBatte,
                  hauteur: hauteurBatte,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
