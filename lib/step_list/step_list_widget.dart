import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reqspec/step_list/http_providor.dart';
import 'package:reqspec/step_list/step_bloc.dart';
import 'package:reqspec/step_list/tree_bloc.dart';

import 'models.dart';
import 'models.dart' as reqspec_models;

class NodeListPage extends StatelessWidget {
  final int treeId;
  late TreeHttpProvider httpProvider;
  late NodeListWidget nodeListWidget;
  final StreamController<Map<String, dynamic>> associationStreamController =
  StreamController<Map<String, dynamic>>();
  final StreamController<Node> nodeClickStreamController =
  StreamController<Node>.broadcast();

  Stream<Node> get nodeClickStream => nodeClickStreamController.stream;

  NodeListPage({Key? key, required this.treeId, required this.httpProvider})
      : super(key: key);

  // Expose the stream so that parent widgets can listen to the association events.
  Stream<Map<String, dynamic>> get associationStream =>
      associationStreamController.stream;

  final StreamController<Node> linkStreamController =
  StreamController<Node>.broadcast();

  Stream<Node> get linkStream => linkStreamController.stream;

  associate_node(Node from_node, Node to_node, NodeListPage from_node_list_page, NodeListPage to_node_list_page) {
    nodeListWidget.associateNode(from_node, to_node, from_node_list_page, to_node_list_page);
  }

  @override
  Widget build(BuildContext context) {
    // Pass the associationStreamController to NodeListWidget
    nodeListWidget = NodeListWidget(
        treeId: treeId,
        associationStreamController: associationStreamController,
        nodeClickStreamController: nodeClickStreamController,
        linkStreamController: linkStreamController);

    // No need to listen here, because the StreamController is passed down
    // and the parent can listen to it directly

    return BlocProvider<NodeBloc>(
      create: (_) => NodeBloc(httpProvider)..add(LoadTreesEvent()),
      child: nodeListWidget,
    );
  }

  // Make sure to close the stream controller when the widget is disposed
  void dispose() {
    associationStreamController.close();
    nodeClickStreamController.close();
  }
}

class NodeListWidget extends StatelessWidget {
  List<Node>? nodes;
  final int treeId;
  final Map<int, GlobalKey> nodeKeys = {}; // Store keys for each node
  final StreamController<Map<String, dynamic>> associationStreamController;
  // Add a getter to expose the stream.
  Stream<Map<String, dynamic>> get associationStream =>
      associationStreamController.stream;
  late BuildContext context;
  final StreamController<Node> nodeClickStreamController; // Add this line
  Stream<Node> get nodeClickStream =>
      nodeClickStreamController.stream; // And this line
  final StreamController<Node> linkStreamController; // Add this line
  Stream<Node> get linkClickStream =>
      linkStreamController.stream; // And this line

  NodeListWidget({
    Key? key,
    required this.treeId,
    this.nodes,
    required this.associationStreamController,
    required this.nodeClickStreamController,
    required this.linkStreamController,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // If steps are provided, build the UI from the provided steps
    // Otherwise, build the UI from the steps in the current state
    this.context = context;
    return buildNodesFromBloc(context);
  }

  associateNode(Node from_node, Node to_node, NodeListPage from_node_list_page, NodeListPage to_node_list_page) {
    context.read<NodeBloc>().add(AssociateNodeEvent(from_node, to_node, from_node_list_page, to_node_list_page));
  }

  Future<Map<String, dynamic>?> _showAssociationsModal(
      BuildContext context, List<AssociatedNode> associations, bool isForward) async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 200, // Adjust the height as needed
          color: Colors.white,
          child: Center(
            child: ListView.builder(
              itemCount: associations.length,
              itemBuilder: (BuildContext context, int index) {
                AssociatedNode associatedNode = associations[index];
                return ListTile(
                  title: Text('Node ID: ${associatedNode.id}'),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      Navigator.pop(context, {'node': associatedNode, 'delete': true});
                    },
                  ),
                  onTap: () {
                    Navigator.pop(context, {'node': associatedNode, 'delete': false});
                  },
                );
              },
            ),
          ),
        );
      },
    );

    // Handle the result
    return result;
  }



  refresh() {
    context.read<NodeBloc>().add(LoadTreesEvent());
  }

  void selectNode(int nodeId) {
    context.read<NodeBloc>().add(SelectNodeEvent(
        this.nodes!.firstWhere((element) => element.id == nodeId)));
  }

  void deselectNode() {
    context.read<NodeBloc>().add(DeselectNodeEvent());
  }

  Widget buildNodeCard(
      Node node,
      bool isSelected,
      BuildContext context,
      bool isEditing,
      ) {
    nodeKeys[node.id] = GlobalKey();

    var editingText = '';
    return GestureDetector(
      key: nodeKeys[node.id],
      onTap: () {
        nodeClickStreamController.add(node);
        if (isSelected) {
          context.read<NodeBloc>().add(DeselectNodeEvent()); // Deselect
        } else {
          context.read<NodeBloc>().add(SelectNodeEvent(node)); // Select
        }
      },
      child: Card(
        color: isSelected ? Colors.lightBlue : null,
        elevation: 2,
        margin: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            ListTile(
              leading: Text(
                node.number,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              title: isEditing && isSelected
                  ? TextField(
                controller: TextEditingController(text: node.text),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                autofocus: true,
                onChanged: (String text) {
                  editingText = text;
                },
                onSubmitted: (String text) {
                  context
                      .read<NodeBloc>()
                      .add(UpdateNodeTextEvent(node, text));
                },
              )
                  : Text(
                node.text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : Colors.black,
                ),
              ),
              trailing: isSelected
                  ? Icon(
                Icons.check_circle_outline,
                color: Colors.white,
              )
                  : null,
            ),
            // Submenu appears as a row of icon buttons when the item is selected
            if (isSelected)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.start, // Align to the start (left)
                  children: [
                    // Use TextButton for a more flat and left-aligned appearance
                    TextButton(
                      onPressed: () async {
                        List<AssociatedNode> forwardAssociations = await context
                            .read<NodeBloc>().getForwardAssociationsOfNode(node.id);
                        var association_modal_data = await _showAssociationsModal(
                            context, forwardAssociations, true);
                        // print('skjfal;skdjf;laksjdf;laksjdf');
                        if (association_modal_data != null) {
                          // Add an event to the stream when an association is tapped.
                          if (association_modal_data['delete']) {
                            context.read<NodeBloc>().add(UnassociateForwardEvent(node, association_modal_data['node']));
                          } else {
                            var response = await context
                                .read<NodeBloc>()
                                .getTreeOfNode(
                                association_modal_data['node'].id, association_modal_data['node'].url);
                            var serializedResponse = jsonDecode(response.body);
                            print(serializedResponse['tree_id']);
                            this.associationStreamController.add({
                              'id': association_modal_data['node'].id,
                              'tree_id': serializedResponse['tree_id']
                            });
                          }

                        }
                      },
                      child: Text('Linked to'),
                      style: TextButton.styleFrom(
                        primary: Colors.lightBlue, // Text Color
                        backgroundColor:
                        Colors.white, // Button background color
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0), // Button padding
                      ),
                    ),
                    SizedBox(width: 8), // Spacing between buttons
                    TextButton(
                      onPressed: () async {
                        List<AssociatedNode> backwardAssociations = await context
                            .read<NodeBloc>().getBackwardAssociationsOfNode(node.id);
                        var association_modal_data = await _showAssociationsModal(
                            context, backwardAssociations, false);
                        if (association_modal_data != null) {
                          // Add an event to the stream when an association is tapped.
                          if (association_modal_data['delete'] == true) {
                            context.read<NodeBloc>().add(UnassociateBackwardEvent(association_modal_data['node'], node));
                          } else {
                            var response = await context
                                .read<NodeBloc>()
                                .getTreeOfNode(
                                association_modal_data['node'].id, association_modal_data['node'].url);
                            var serializedResponse = jsonDecode(response.body);
                            print(serializedResponse['tree_id']);
                            this.associationStreamController.add({
                              'id': association_modal_data['node'].id,
                              'tree_id': serializedResponse['tree_id']
                            });
                          }

                        }
                      },
                      child: Text('Linked from'),
                      style: TextButton.styleFrom(
                        primary: Colors.lightBlue, // Text Color
                        backgroundColor:
                        Colors.white, // Button background color
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0), // Button padding
                      ),
                    ),
                    SizedBox(width: 8), // Spacing between buttons
                    TextButton(
                      onPressed: () {
                        // Emit the node object when the "Link" button is clicked
                        linkStreamController.add(node);
                      },
                      child: Text('Link'),
                      style: TextButton.styleFrom(
                        primary: Colors.lightBlue, // Text Color
                        backgroundColor:
                        Colors.white, // Button background color
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0), // Button padding
                      ),
                    ),
                  ],
                ),
              ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Card(
                  color: Colors.lightBlue,
                  elevation: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_upward_rounded),
                        onPressed: () {
                          context.read<NodeBloc>().add(MoveNodeUpEvent(node));
                          print('Move ${node.text} up');
                          // Handle move up
                        },
                        color: Colors.white,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_downward_rounded),
                        onPressed: () {
                          context.read<NodeBloc>().add(MoveNodeDownEvent(node));
                          print('Move ${node.text} down');
                          // Handle move down
                        },
                        color: Colors.white,
                      ),
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_right_rounded),
                        onPressed: () {
                          context
                              .read<NodeBloc>()
                              .add(IndentNodeForwardEvent(node));
                          print('Indent ${node.text} to the right');
                        },
                        color: Colors.white,
                      ),
                      IconButton(
                        icon: Icon(Icons.keyboard_arrow_left_rounded),
                        onPressed: () {
                          context
                              .read<NodeBloc>()
                              .add(IndentNodeBackwardEvent(node));
                          print('Indent ${node.text} to the left');
                        },
                        color: Colors.white,
                      ),
                      IconButton(
                        icon: Icon(Icons.delete_forever_rounded),
                        onPressed: () {
                          context.read<NodeBloc>().add(DeleteNodeEvent(node));
                          print('Delete ${node.text}');
                        },
                        color: Colors.white,
                      ),
                      !isEditing
                          ? IconButton(
                        icon: Icon(Icons.edit),
                        onPressed: () {
                          context
                              .read<NodeBloc>()
                              .add(EditNodeEvent(node.id));
                          // Handle delete
                        },
                        color: Colors.white,
                      )
                          : IconButton(
                          onPressed: () {
                            context.read<NodeBloc>().add(
                                UpdateNodeTextEvent(node, editingText));
                          },
                          icon: Icon(
                            Icons.check,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
              ),

            // ... existing submenu icons
          ],
        ),
      ),
    );
  }

  Widget buildNodesFromBloc(BuildContext context) {
    return BlocBuilder<NodeBloc, NodeState>(
      builder: (context, state) {
        if (state is InitialNodeState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is TreesLoadedState ||
            state is TreesNumberedState ||
            state is NodeSelectedState ||
            state is EditingNodeState) {
          // final steps = state is treesLoadedState
          //     ? state.trees.first.steps
          //     : (state as treesNumberedState).trees.first.steps;
          reqspec_models.Tree tree =
          gettreeById((state as dynamic).trees, treeId);
          var nodes = getAllNodes(tree);
          this.nodes = nodes;
          var selectedNodeId = -1;
          var isEditing = false;
          if (state is NodeSelectedState) {
            selectedNodeId = (state as dynamic).selectedNode.id;
          }
          if (state is EditingNodeState) {
            selectedNodeId = state.editingNodeId;
            isEditing = true;
          }

          // var treeType = convertWord(tree.type);

          return Card(
            margin: EdgeInsets.all(10.0),
            elevation: 4.0, // Increased elevation
            borderOnForeground: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
              side: BorderSide(
                  color: Colors.blueGrey[100]!, width: 1.0), // Border
            ),
            color: Colors.blueGrey[50], // Light background color
            child: Padding(
              padding: EdgeInsets.all(8.0), // Inner padding
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ListTile(
                        title: Text(
                          'Flow',
                          style: TextStyle(
                            fontWeight: FontWeight.bold, // Bold title
                            fontSize: 18,
                          ),
                        ),
                      ),
                      ...getNodeList(
                        nodes,
                        selectedNodeId,
                        context,
                        isEditing,
                      ),
                    ],
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton(
                      icon: Icon(Icons.add,
                          color: Colors.blue), // Styled add button
                      onPressed: () async {
                        String? newText = await addNodeModal(context);
                        if (newText != null) {
                          context.read<NodeBloc>().add(AddNodeEvent(
                              newText,
                              (state is NodeSelectedState)
                                  ? state.selectedNode
                                  : tree.rootNode,
                              tree));
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (state is ErrorState) {
          return Center(child: Text('Error: ${state.message}'));
        } else {
          return const SizedBox(); // Fallback for any other unhandled states
        }
      },
    );
  }

  String convertWord(String word) {
    if (word.isEmpty) {
      return word;
    }
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }

  void main() {
    String word = "THIS";
    String convertedWord = convertWord(word);
    print(convertedWord); // This
  }

  List<Widget> getNodeList(
      List<Node> nodes,
      int selectedNodeId,
      BuildContext context,
      bool isEditing,
      ) {
    // Map each step to a widget using the buildStepCard function
    // and then convert it to a list using toList().
    List<Widget> nodeWidgets = nodes.map<Widget>((node) {
      return buildNodeCard(node, node.id == selectedNodeId, context, isEditing);
    }).toList();

    return nodeWidgets; // Use the list of widgets here
  }

  getAllNodes(reqspec_models.Tree tree) {
    print(tree.rootNode.children);
    List<Node> nodeList = [];
    for (var child in tree.rootNode.children) {
      _getAllNodes(child, nodeList);
    }
    return nodeList;
  }

  _getAllNodes(Node root, List<Node> nodeList) {
    nodeList.add(root);
    for (var child in root.children) {
      _getAllNodes(child, nodeList);
    }
  }

  gettreeById(List<reqspec_models.Tree> trees, int treeId) {
    for (var tree in trees) {
      if (tree.id == treeId) {
        return tree;
      }
    }
    throw Exception('The tree id specified dosen\'t exist');
  }

  Future<String?> addNodeModal(BuildContext context) async {
    TextEditingController textController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Node'),
          content: TextField(
            controller: textController,
            decoration: InputDecoration(hintText: "Enter node text here"),
            onSubmitted: (String text) {
              Navigator.of(context).pop(text);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop(null); // Dismiss and return null
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop(textController.text); // Return text
              },
            ),
          ],
        );
      },
    );
  }
}
