import 'dart:async';

import 'package:flutter/material.dart';

import '/db/db.dart';
import '/db/models/tour.dart';
import '/utils/evresi_page_route.dart';
import '/views/editor/tour.dart';
import 'editor/home.dart';

class EditorPage extends StatefulWidget {
  const EditorPage({Key? key}) : super(key: key);

  @override
  State<EditorPage> createState() => _EditorPageState();
}

class _EditorPageState extends State<EditorPage> {
  final GlobalKey<NavigatorState> navKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
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
    );
  }
}

class Sidebar extends StatefulWidget {
  const Sidebar({Key? key, required this.navKey}) : super(key: key);

  final GlobalKey<NavigatorState> navKey;

  @override
  State<StatefulWidget> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> {
  StreamSubscription<Event>? _eventsSubscription;
  List<TourSummary> _tours = [];

  @override
  void initState() {
    super.initState();

    // subscribe to events from the db and request the list of tours
    _eventsSubscription = instance.events.listen(_onEvent);
    instance.requestEvent(const ToursEventDescriptor());
  }

  @override
  void dispose() {
    _eventsSubscription?.cancel();

    super.dispose();
  }

  void _onEvent(Event event) {
    if (event.desc is ToursEventDescriptor) {
      setState(() {
        _tours = event.value;
      });
    }
  }

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
                onTap: () => widget.navKey.currentState?.push(
                  EvresiPageRoute((context) => const Home()),
                ),
              ),
              const _SidebarHeader("Tours"),
              for (var item in _tours)
                _SidebarItem(
                  item.name,
                  key: ValueKey(item.id),
                  leading: const Icon(Icons.map),
                  onTap: () => widget.navKey.currentState?.push(
                    EvresiPageRoute((context) => TourEditor(tourId: item.id)),
                  ),
                ),
              _SidebarItem(
                "New Tour",
                leading: const Icon(Icons.add),
                onTap: () {
                  instance.createTour(Tour(name: "New tour", desc: ""));
                },
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
                  child: const Text("PUBLISH"),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.secondary,
                    ),
                    foregroundColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.onSecondary,
                    ),
                  ),
                  onPressed: () {},
                  child: const Text("SYNC"),
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
    Key? key,
    required this.leading,
    required this.onTap,
  }) : super(key: key);

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
