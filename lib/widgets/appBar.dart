import 'package:flutter/material.dart';

AppBar buildAppBar(BuildContext context, [List<Widget>? actions]) {
  return AppBar(
    iconTheme: Theme.of(context).iconTheme,
    title: Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white,
        ),
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(50),
          right: Radius.circular(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Text(
          'Better alarm clock',
          style: Theme.of(context).textTheme.headline6,
        ),
      ),
    ),
    actions: actions,
    backgroundColor: Colors.transparent,
  );
}
