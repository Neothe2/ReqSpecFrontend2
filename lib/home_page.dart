import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:reqspec/step_list/http_providor.dart';

import 'step_list/models.dart';
import 'step_list/step_list_widget.dart';

import 'package:http/http.dart' as http;

class MyHomePage extends StatefulWidget {
  final String title;

  const MyHomePage({Key? key, required this.title}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<NodeListPage> alternate_flows = [];
  List<NodeListPage> exception_flows = [];
  late NodeListPage main_flow;
  dynamic use_case_description = {};
  Map<int, NodeListPage> flow_map = {};
  bool treesFetched = false;
  bool selectionState = false;
  Node? from_node;
  NodeListPage? from_node_list_page;

  void scrollToNode(GlobalKey key) {
    // final GlobalKey key = exception_flows[0].nodeListWidget.nodeKeys[nodeId]!;

    // Check if the context for the key is available
    if (key.currentContext != null) {
      // Scroll to the position of the key
      Scrollable.ensureVisible(key.currentContext!,
          duration: Duration(milliseconds: 1000));
    }
  }

  //TREES
  Future<void> getTrees(int use_case_description_id) async {
    var serializedData = await fetchUseCaseDescription(use_case_description_id);
    use_case_description = serializedData;

    processFlowData(serializedData['alternate_flows'], AlternateFlowHttpProvidor(), alternate_flows);
    processFlowData(serializedData['exception_flows'], ExceptionFlowHttpProvidor(), exception_flows);
    setupMainFlow(serializedData['main_flow']);

    setState(() {
      treesFetched = true;
    });
  }

  Future<dynamic> fetchUseCaseDescription(int id) async {
    var response = await http.get(Uri.parse('http://10.0.2.2:8000/reqspec/use_case_descriptions/$id'));
    return jsonDecode(response.body);
  }

  void processFlowData(List<dynamic> flowIds, TreeHttpProvider httpProvider, List<NodeListPage> flowsList) {
    for (var flowId in flowIds) {
      var nodeListPage = NodeListPage(treeId: flowId, httpProvider: httpProvider);
      flowsList.add(nodeListPage);
      flow_map[flowId] = nodeListPage;
      setupNodeListPageListeners(nodeListPage);
    }
  }

  void setupNodeListPageListeners(NodeListPage nodeListPage) {
    nodeListPage.associationStream.listen((event) {
      handleAssociationEvent(event, nodeListPage);
    });
    nodeListPage.nodeClickStream.listen((event) {
      nodeClicked(event, nodeListPage);
    });
    nodeListPage.linkStream.listen((event) {
      handleLinkEvent(event, nodeListPage);
    });
  }

  void handleAssociationEvent(dynamic event, NodeListPage nodeListPage) {
    final GlobalKey key = flow_map[event['tree_id']]!.nodeListWidget.nodeKeys[event['id']]!;
    scrollToNode(key);
    flow_map[event['tree_id']]!.nodeListWidget.selectNode(event['id']);
    nodeListPage.nodeListWidget.deselectNode();
  }

  void handleLinkEvent(Node event, NodeListPage nodeListPage) {
    this.from_node = event;
    this.from_node_list_page = nodeListPage;
    setState(() {
      selectionState = true;
    });
  }

  void setupMainFlow(int mainFlowId) {
    main_flow = NodeListPage(treeId: mainFlowId, httpProvider: StepHttpProvider());
    flow_map[mainFlowId] = main_flow;
    setupNodeListPageListeners(main_flow);
  }
  //TREES//

  Widget _buildNotificationWidget() {
    return Container(
      padding: EdgeInsets.all(8.0),
      color: Colors.blueAccent,
      width: double.infinity,
      height: 50,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Select a node',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 20),
            textAlign: TextAlign.center,

          ),
        ],
      ),
    );
  }

  void nodeClicked(Node event, NodeListPage node_list_page) {
    if (selectionState) {
      if (from_node != event) {
        print('This should be selected from ${this.from_node!.text}:');
        final snackBar = SnackBar(
          content: Text("The Node '${event.text}' has been associated to '${this.from_node!.text}'"),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {
              // Some code to undo the change.
            },
            backgroundColor: Colors.lightGreen,
            textColor: Colors.black,
          ),
        );

        // Show the snackbar
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
        from_node_list_page!.associate_node(
            this.from_node!, event, this.from_node_list_page!, node_list_page);
      }
      setState(() {
        selectionState = false;
      });
      from_node = null;
      from_node_list_page = null;
    }
    print(event.text);
  }

  @override
  void initState() {
    super.initState();
    getTrees(1);
  }

  @override
  Widget build(BuildContext context) {
    var text = 'Add Alternate Flows';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Stack(
        children: [
          ListView(
            children: treesFetched
                ? <Widget>[
                  Text('data'),

              main_flow,
              // TextButton(
              //   onPressed: () async {
              //     await addAlternateFlow();
              //   },
              //   child: Text(text),
              //   style: ButtonStyle(
              //     backgroundColor:
              //     MaterialStatePropertyAll(Colors.yellow),
              //     foregroundColor: MaterialStatePropertyAll(Colors.black),
              //   ),
              // ),
              // Column(
              //   children: alternate_flows,
              // ),
              // TextButton(
              //   onPressed: () async {
              //     await addExceptionFlow();
              //   },
              //   child: Text('Add Exception Flow'),
              //   style: ButtonStyle(
              //     backgroundColor:
              //     MaterialStatePropertyAll(Colors.yellow),
              //     foregroundColor: MaterialStatePropertyAll(Colors.black),
              //   ),
              // ),

              // Column(
              //   children: exception_flows,
              // )
              // NodeListPage(
              //   treeId: 6, // Replace with your second flowId
              // ),
            ]
                : [],
          ),
          if (selectionState)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _buildNotificationWidget(),
            ),
        ],
      ),
    );
  }

  addAlternateFlow() async {
    var response = await http.post(
        Uri.parse('http://10.0.2.2:8000/reqspec/alternate_flows/'),
        body: {});

    var serializedResponse = jsonDecode(response.body);
    setState(() {
      use_case_description['alternate_flows'] = [
        ...use_case_description['alternate_flows'],
        serializedResponse['id']
      ];
    });
    var newresponse = await http.put(
        Uri.parse('http://10.0.2.2:8000/reqspec/use_case_descriptions/1/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(use_case_description));

    print(newresponse.body);
    print(newresponse.statusCode);
    setState(() {
      alternate_flows.add(NodeListPage(
        treeId: serializedResponse['id'], // Replace with your first flowId
        httpProvider: AlternateFlowHttpProvidor(),
      ));
    });
  }

  addExceptionFlow() async {
    var response = await http.post(
        Uri.parse('http://10.0.2.2:8000/reqspec/exception_flows/'),
        body: {});

    var serializedResponse = jsonDecode(response.body);
    setState(() {
      use_case_description['exception_flows'] = [
        ...use_case_description['exception_flows'],
        serializedResponse['id']
      ];
    });
    var newresponse = await http.put(
        Uri.parse('http://10.0.2.2:8000/reqspec/use_case_descriptions/1/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(use_case_description));

    print(newresponse.body);
    print(newresponse.statusCode);
    setState(() {
      exception_flows.add(NodeListPage(
        treeId: serializedResponse['id'], // Replace with your first flowId
        httpProvider: ExceptionFlowHttpProvidor(),
      ));
    });
  }
}
//  getTrees(int use_case_description_id) async {
//     var response = await http.get(Uri.parse(
//         'http://10.0.2.2:8000/reqspec/use_case_descriptions/$use_case_description_id'));
//     var serializedData = jsonDecode(response.body);
//     use_case_description = serializedData;
//     for (var alternateFlowId in serializedData['alternate_flows']) {
//       var nodeListPage = NodeListPage(
//         treeId: alternateFlowId, // Replace with your first flowId
//         httpProvider: AlternateFlowHttpProvidor(),
//       );
//       alternate_flows.add(nodeListPage);
//       flow_map[alternateFlowId] = nodeListPage;
//       nodeListPage.associationStream.listen((event) {
//         final GlobalKey key =
//         flow_map[event['tree_id']]!.nodeListWidget.nodeKeys[event['id']]!;
//         scrollToNode(key);
//         flow_map[event['tree_id']]!.nodeListWidget.selectNode(event['id']);
//         nodeListPage.nodeListWidget.deselectNode();
//       });
//       nodeListPage.nodeClickStream.listen((event) {
//         nodeClicked(event, nodeListPage);
//       });
//
//       nodeListPage.linkStream.listen((event) {
//         this.from_node = event;
//         setState(() {
//           selectionState = true;
//         });
//         from_node_list_page = nodeListPage;
//       });
//     }
//     for (var exceptionFlowId in serializedData['exception_flows']) {
//       var nodeListPage = NodeListPage(
//         treeId: exceptionFlowId, // Replace with your first flowId
//         httpProvider: ExceptionFlowHttpProvidor(),
//       );
//       exception_flows.add(nodeListPage);
//       flow_map[exceptionFlowId] = nodeListPage;
//       nodeListPage.associationStream.listen((event) {
//         final GlobalKey key =
//         flow_map[event['tree_id']]!.nodeListWidget.nodeKeys[event['id']]!;
//         scrollToNode(key);
//         flow_map[event['tree_id']]!.nodeListWidget.selectNode(event['id']);
//         nodeListPage.nodeListWidget.deselectNode();
//       });
//       nodeListPage.nodeClickStream.listen((event) {
//         nodeClicked(event, nodeListPage);
//       });
//
//       nodeListPage.linkStream.listen((event) {
//         this.from_node = event;
//         this.from_node_list_page = nodeListPage;
//         setState(() {
//           selectionState = true;
//         });
//       });
//     }
//
//     main_flow = NodeListPage(
//       treeId: serializedData['main_flow'], // Replace with your first flowId
//       httpProvider: StepHttpProvider(),
//     );
//
//     flow_map[serializedData['main_flow']] = main_flow;
//     main_flow.associationStream.listen((event) {
//       final GlobalKey key =
//       flow_map[event['tree_id']]!.nodeListWidget.nodeKeys[event['id']]!;
//       scrollToNode(key);
//       flow_map[event['tree_id']]!.nodeListWidget.selectNode(event['id']);
//       main_flow.nodeListWidget.deselectNode();
//     });
//
//     main_flow.nodeClickStream.listen((event) {
//       nodeClicked(event, main_flow);
//     });
//
//     main_flow.linkStream.listen((event) {
//       this.from_node = event;
//       from_node_list_page = main_flow;
//       setState(() {
//         selectionState = true;
//       });
//     });
//
//     setState(() {
//       treesFetched = true;
//     });
//   }