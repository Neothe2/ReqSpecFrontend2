import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import 'http_providor.dart';
import 'models.dart';

import 'step_bloc.dart';

//TODO make the order change on every event

class NodeBloc extends Bloc<TreeEvent, NodeState> {
  List<Tree> trees = [];
  var url = 'http://192.168.0.4:8000/reqspec';
  late TreeHttpProvider httpService;
  NodeBloc(this.httpService) : super(InitialNodeState()) {
    // this.httpService = TreeHttpProvider();
    on<LoadTreesEvent>(_onLoadTreesEvent);
    on<NumberNodesEvent>(_onNumberNodesEvent);
    on<SelectNodeEvent>(_onNodeSelectedEvent);
    on<EditNodeEvent>(_onEditNodeEvent);
    on<UpdateNodeTextEvent>(_onUpdateNodeTextEvent);
    on<MoveNodeUpEvent>(_onMoveNodeUpEvent);
    on<MoveNodeDownEvent>(_onMoveNodeDownEvent);
    on<IndentNodeForwardEvent>(_onIndentNodeForwardEvent);
    on<IndentNodeBackwardEvent>(_onIndentNodeBackwardEvent);
    on<DeleteNodeEvent>(_onDeleteNodeEvent);
    on<AddNodeEvent>(_onAddNodeEvent);
    on<DeselectNodeEvent>(_onDeselectNode);
    on<AssociateNodeEvent>(_onAssociateNode);
  }

  FutureOr<void> _onIndentNodeBackwardEvent(
    IndentNodeBackwardEvent event,
    Emitter<NodeState> emit,
  ) async {
    if (event.node.parent != null && event.node.parent!.parent != null) {
      var parent = event.node.parent;
      var newParent = event.node.parent!.parent!;
      // bool newParentIsTree = false;
      // if (event.node.parent!.parent == null) {
      //   newParent = event.node.parent!.tree;
      //   newParentIsTree = true;
      // } else {
      //   newParent = event.node.parent!.parent;
      // }
      // var requestBody = {};
      // if (!newParentIsTree) {
      //   requestBody = {
      //     "parent": newParent.id, // Assuming newParent.id is not null
      //     "tree": null, // Sending null as required
      //     "id": event.node.id,
      //     "type": event.node.type
      //   };
      // } else {
      //   requestBody = {
      //     "parent": null, // Sending null as required
      //     "tree": newParent.id, // Assuming newParent.id is not null
      //     "id": event.node.id,
      //     "type": event.node.type
      //   };
      // }
      //
      // var response = await http.patch(
      //     Uri.parse('${url}/reqspec/nodes/${event.node.id}/'),
      //     headers: {"Content-Type": "application/json"},
      //     body: jsonEncode(requestBody)); // Encoding the request body as JSON
      //
      // print(response.body);
      // print(response.statusCode);
      httpService.httpIndentNodeBackward(event.node, newParent);

      Map<String, int> orderMap = {};

      bool targetNodeReached = false;
      orderMap[event.node.id.toString()] = parent!.order + 1;
      event.node.order = parent.order + 1;

      for (Node node in newParent.getChildren()) {
        if (targetNodeReached) {
          orderMap[node.id.toString()] = node.order + 1;
          node.order = node.order + 1;
        } else {
          if (node == parent) {
            targetNodeReached = true;
          }
        }
      }
      newParent.addAsChild(event.node);
      // for (var i = 1; i <= newParent.getChildren().length; i++) {
      //   if (!(newParent.getChildren()[i - 1].order == i)) {
      //     newParent.getChildren()[i - 1].order = i;
      //     orderMap[(newParent.getChildren()[i - 1].id).toString()] = i;
      //   }
      // }
      for (var i = 1; i <= parent.children.length; i++) {
        if (!(parent.children[i - 1].order == i)) {
          parent.children[i - 1].order = i;
          orderMap[(parent.children[i - 1].id).toString()] = i;
        }
      }

      print(orderMap);
      //
      // http.post(
      //   Uri.parse('${url}/reqspec/nodes/set_order/'),
      //   body: jsonEncode(orderMap),
      // );

      httpService.httpSetNodeOrder(orderMap);

      parent.sortNodes();
      newParent.sortNodes();
      numberNodes();

      emit(NodeSelectedState(trees, event.node));
    }
  }

  FutureOr<void> _onIndentNodeForwardEvent(
      IndentNodeForwardEvent event, Emitter<NodeState> emit) async {
    if (event.node.order > 1) {
      var parent = event.node.parent!;
      Node newParent = parent.getNodeByOrder(event.node.order - 1);
      // var requestBody = {
      //   "parent": newParent.id, // Assuming newParent.id is not null
      //   "tree": null, // Sending null as required
      //   "id": event.node.id,
      //   "type": event.node.type
      // };
      //
      // var response = await http.patch(
      //     Uri.parse('${url}/reqspec/nodes/${event.node.id}/'),
      //     headers: {"Content-Type": "application/json"},
      //     body: jsonEncode(requestBody)); // Encoding the request body as JSON
      //
      // print(response.body);
      // print(response.statusCode);help my texfffffffffffffffffffffmy textr cant get out nooooooo
      httpService.httpIndentNodeForward(event.node, newParent);

      newParent.addAsChild(event.node);

      Map<String, int> orderMap = {};
      for (var i = 1; i <= newParent.children.length; i++) {
        if (!(newParent.children[i - 1].order == i)) {
          newParent.children[i - 1].order = i;
          orderMap[(newParent.children[i - 1].id).toString()] = i;
        }
      }
      for (var i = 1; i <= parent.getChildren().length; i++) {
        if (!(parent.getChildren()[i - 1].order == i)) {
          parent.getChildren()[i - 1].order = i;
          orderMap[(parent.getChildren()[i - 1].id).toString()] = i;
        }
      }

      // var a = {"parent": newParent.id, "tree": (null).toString()};
      // print(a);
      //
      // print(orderMap);
      //
      // http.post(Uri.parse('${url}/reqspec/nodes/set_order/'),
      //     body: jsonEncode(orderMap));
      httpService.httpSetNodeOrder(orderMap);

      parent.sortNodes();
      newParent.sortNodes();
      numberNodes();

      emit(NodeSelectedState(trees, event.node));
    }
  }

  FutureOr<void> _onLoadTreesEvent(
    LoadTreesEvent event,
    Emitter<NodeState> emit,
  ) async {
    final response = await httpService.httpLoadTrees();
    if (response.statusCode == 200) {
      trees = parseTreesFromJson(response.body);
      emit(TreesLoadedState(trees));
      add(NumberNodesEvent(trees));
    } else {
      emit(ErrorState('Failed to load trees'));
    }
  }

  void _onNumberNodesEvent(
    NumberNodesEvent event,
    Emitter<NodeState> emit,
  ) {
    for (var tree in trees) {
      _numberNodesRecursive(tree.rootNode.children);
    }
    emit(TreesNumberedState(trees));
  }

  // void _numberNodesRecursive(List<Node> nodes, [String prefix = '']) {
  //   for (int i = 0; i < nodes.length; i++) {
  //     var currentNode = nodes[i];
  //     currentNode.number = prefix.isEmpty ? '${i + 1}' : '$prefix.${i + 1}';
  //     if (currentNode.children.isNotEmpty) {
  //       _numberNodesRecursive(currentNode.children, currentNode.number);
  //     }
  //   }
  // }

  FutureOr<void> _onNodeSelectedEvent(
    SelectNodeEvent event,
    Emitter<NodeState> emit,
  ) async {
    emit(NodeSelectedState(trees, event.node));
  }

  FutureOr<void> _onEditNodeEvent(
    EditNodeEvent event,
    Emitter<NodeState> emit,
  ) async {
    emit(EditingNodeState(trees, event.nodeId));
  }

  FutureOr<void> _onUpdateNodeTextEvent(
    UpdateNodeTextEvent event,
    Emitter<NodeState> emit,
  ) async {
    final response =
        await httpService.httpUpdateNodeText(event.node, event.newText);
    if (response.statusCode == 200) {
      event.node.text = event.newText;
      emit(NodeSelectedState(trees, event.node));
    } else {
      emit(ErrorState('Failed to update node text'));
    }
  }

  FutureOr<void> _onMoveNodeUpEvent(
    MoveNodeUpEvent event,
    Emitter<NodeState> emit,
  ) async {
    Node parent = event.node.parent!;
    if (event.node.order > 1) {
      Node nodeToSwap = parent.getNodeByOrder(event.node.order - 1);

      // Use TreeHttpProvider for HTTP requests
      final responseSwap =
          await httpService.httpMoveNode(nodeToSwap, event.node.order);
      final responseCurrent =
          await httpService.httpMoveNode(event.node, event.node.order - 1);

      if (responseSwap.statusCode == 200 && responseCurrent.statusCode == 200) {
        nodeToSwap.order = event.node.order;
        event.node.order -= 1;
        parent.sortNodes();
        numberNodes();
        emit(NodeSelectedState(trees, event.node));
      } else {
        emit(ErrorState('Failed to move node up'));
      }
    }
  }

  FutureOr<void> _onMoveNodeDownEvent(
    MoveNodeDownEvent event,
    Emitter<NodeState> emit,
  ) async {
    Node parent = event.node.parent!;
    if (event.node.order < parent.children.length) {
      Node nodeToSwap = parent.getNodeByOrder(event.node.order + 1);

      // Use TreeHttpProvider for HTTP requests
      final responseSwap =
          await httpService.httpMoveNode(nodeToSwap, event.node.order);
      final responseCurrent =
          await httpService.httpMoveNode(event.node, event.node.order + 1);

      if (responseSwap.statusCode == 200 && responseCurrent.statusCode == 200) {
        nodeToSwap.order = event.node.order;
        event.node.order += 1;
        parent.sortNodes();
        numberNodes();
        emit(NodeSelectedState(trees, event.node));
      } else {
        emit(ErrorState('Failed to move node down'));
      }
    }
  }

  FutureOr<void> _onDeleteNodeEvent(
    DeleteNodeEvent event,
    Emitter<NodeState> emit,
  ) async {
    dynamic parent = event.node.parent ?? event.node.tree;
    final response = await httpService.httpDeleteNode(event.node);
    print(response.statusCode);
    if (response.statusCode == 204) {
      parent!.removeChild(event.node);
      _updateNodeOrders(parent);
      emit(TreesNumberedState(trees));
    } else {
      emit(ErrorState('Failed to delete node'));
    }
  }

  void _updateNodeOrders(Node parent) {
    // int order = 1;
    // for (var node in parent.getChildren()) {
    //   node.order = order++;
    // }
    Map<String, int> orderMap = {};

    for (var i = 1; i <= parent.children.length; i++) {
      if (!(parent.children[i - 1].order == i)) {
        parent.children[i - 1].order = i;
        orderMap[(parent.children[i - 1].id).toString()] = i;
      }
    }

    print(orderMap);

    httpService.httpSetNodeOrder(orderMap);
  }

  FutureOr<void> _onAddNodeEvent(
    AddNodeEvent event,
    Emitter<NodeState> emit,
  ) async {
    var order = event.under.children.length + 1;
    final response = await httpService.httpAddNode(
        event.under, event.tree, event.text, order);
    if (response.statusCode == 201) {
      var serializedResponse = jsonDecode(response.body);
      var new_node = Node(
          id: serializedResponse['id'],
          text: event.text,
          // type: serializedResponse['type'],
          forwardNodeAssociations: [],
          backwardNodeAssociations: [],
          children: [],
          order: order,
          parent: event.under);
      if (event.under.parent != null) {
        event.under.parent!.children.add(new_node);
      } else {
        event.under.children.add(new_node);
      }
      event.under.sortNodes();
      numberNodes();
      emit(NodeSelectedState(trees, new_node));
    } else {
      print(response.body);
      emit(ErrorState('Failed to add node'));
    }
  }

  Future<http.Response> getTreeOfNode(int nodeId, String url) async {
    return await httpService.getTreeid(nodeId, url);
  }

  // Future<List<Tree>> _fetchTrees() async {
  //   final uri = Uri.parse('${url}/trees/');
  //   final response = await http.get(uri);
  //   if (response.statusCode == 200) {
  //     print(response.body);
  //     return parseTreesFromJson(response.body);
  //   } else {
  //     print(response.body);
  //     throw Exception('Failed to load trees');
  //   }
  // }

  void numberNodes() {
    for (var tree in trees) {
      _numberNodesRecursive(tree.rootNode.children);
    }
  }

  void _numberNodesRecursive(List<Node> nodes, [String prefix = '']) {
    for (int i = 0; i < nodes.length; i++) {
      var currentNode = nodes[i];
      currentNode.number = prefix.isEmpty ? '${i + 1}' : '$prefix.${i + 1}';

      if (currentNode.children.isNotEmpty) {
        _numberNodesRecursive(currentNode.children, currentNode.number);
      }
    }
  }

  FutureOr<void> _onDeselectNode(
      DeselectNodeEvent event, Emitter<NodeState> emit) {
    emit(TreesNumberedState(trees));
  }

  FutureOr<void> _onAssociateNode(AssociateNodeEvent event, Emitter<NodeState> emit) async {
    await httpService.associateNode(event.from_node.id, event.to_node.id);
    await event.from_node_list_page.nodeListWidget.refresh();
    await event.to_node_list_page.nodeListWidget.refresh();
    event.from_node_list_page.nodeListWidget.selectNode(event.from_node.id);
    event.to_node_list_page.nodeListWidget.selectNode(event.to_node.id);
  }
}

// List<Tree> parseTreesFromJson(String jsonString) {
//   final jsonData = json.decode(jsonString);
//   List<Tree> trees = [];
//   for (var treeJson in jsonData) {
//     Tree tree = Tree(
//         id: treeJson['id'],
//         type: treeJson['type'],
//         children: treeJson['children'] != null
//             ? parseNodes(treeJson['children'], null, null)
//             : []);
//     trees.add(tree);
//   }
//   return trees;
// }
//
// List<Node> parseNodes(List<dynamic> nodesJson, Node? parent, Tree? tree) {
//   List<Node> nodes = [];
//   for (var nodeJson in nodesJson) {
//     Node node = Node(
//       id: nodeJson['id'],
//       text: nodeJson['text'],
//       type: nodeJson['type'],
//       parent: parent,
//       forwardNodeAssociations:
//           List<int>.from(nodeJson['forward_step_associations'] ?? []),
//       children: parseNodes(nodeJson['children'] ?? [], null, tree),
//       tree: tree,
//       order: nodeJson['order'],
//     );
//     nodes.add(node);
//   }
//   return nodes;
// }
