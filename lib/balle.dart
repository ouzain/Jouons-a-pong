import 'package:flutter/material.dart';

class Balle extends StatelessWidget {
  // On rend le diamètre de la balle statique pour pouvoir y accéder 
  // depuis la logique de jeu (testerBordures, etc.).
  static const double diametre = 50;

  const Balle({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diametre,
      height: diametre,
      decoration: const BoxDecoration(
        color: Colors.red,
        shape: BoxShape.circle,
      ),
    );
  }
}
