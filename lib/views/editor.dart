import 'package:builder/utils/evresi_page_route.dart';
import 'package:flutter/material.dart';

import 'editor/home.dart';

class EditorPage extends StatelessWidget {
  EditorPage({Key? key}) : super(key: key);

  final GlobalKey<NavigatorState> navKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            Sidebar(navKey: navKey),
            Expanded(
              child: Navigator(
                key: navKey,
                onGenerateInitialRoutes: (navigator, initialRoute) =>
                    [EvresiPageRoute((context) => const Home())],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Sidebar extends StatelessWidget {
  const Sidebar({Key? key, required this.navKey}) : super(key: key);

  final GlobalKey<NavigatorState> navKey;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 275,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SidebarItem(
                "Home",
                leading: const Icon(Icons.home),
                onTap: () => navKey.currentState?.push(
                  EvresiPageRoute((context) => const Home()),
                ),
              ),
              const _SidebarHeader("Tours"),
              /*for (var entry in db.tours)
                _SidebarItem(
                  leading: const Icon(Icons.map),
                  title: entry.value.name,
                  onTap: () => navKey.currentState?.push(
                    EvresiPageRoute(
                        (context) => TourScreen(tourId: entry.key)),
                ),*/
              _SidebarItem(
                "New Tour",
                leading: const Icon(Icons.add),
                onTap: () {},
              ),
              const Expanded(
                child: _SidebarControls(),
              ),
            ],
          ),
        ),
        const VerticalDivider(
          width: 1,
          thickness: 1,
        ),
      ],
    );
  }
}

class _SidebarControls extends StatelessWidget {
  const _SidebarControls({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        const Divider(
          thickness: 1,
          height: 1,
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.0,
                    ),
                    child: Text("PUBLISH"),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  onPressed: () {},
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 12.0,
                    ),
                    child: Text("SYNC"),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              IconButton(
                onPressed: () {},
                splashRadius: 20.0,
                icon: const Icon(Icons.settings),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 8.0,
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color.fromARGB(255, 128, 128, 128),
        ),
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem(
    this.title, {
    required this.leading,
    required this.onTap,
  });

  final Widget leading;
  final String title;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: leading,
      title: Text(
        title,
        softWrap: false,
        overflow: TextOverflow.fade,
      ),
      onTap: onTap,
    );
  }
}
