import 'dart:async';
import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'http_providor.dart';
import 'models.dart';

import 'step_bloc.dart';

//TODO make the order change on every event

class NodeBloc extends Bloc<TreeEvent, NodeState> {
  List<Tree> _trees = [];
  get trees => _trees;
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
    on<UnassociateForwardEvent>(_onUnassociateForwardEvent);
    on<UnassociateBackwardEvent>(_onUnassociateBackwardEvent);
  }

//INDENT NODE BACKWARDS BEGINNING
  FutureOr<void> _onIndentNodeBackwardEvent(
    IndentNodeBackwardEvent event,
    Emitter<NodeState> emit,
  ) async {
    if (event.node.parent != null && event.node.parent!.parent != null) {
      var parent = event.node.parent;
      var newParent = event.node.parent!.parent!;
      _makeHttpIndentNodeBackwardRequest(event.node, newParent);
      _addChildToNewParentBackward(event.node, newParent);
      Map<String, int> orderMap = _updateNodeOrdersForBackwardIndent(event.node, parent!, newParent);
      print(orderMap);
      _makeHttpSetNodeOrderRequest(orderMap);
      _sortNodesAndEmitState(parent, newParent, event.node, emit);
    }
  }

  Map<String, int> _updateNodeOrdersForBackwardIndent(
      Node node, Node parent, Node newParent) {
    Map<String, int> orderMap = {};
    bool targetNodeReached = false;
    orderMap[node.id.toString()] = parent.order + 1;
    node.order = parent.order + 1;

    for (Node childNode in newParent.getChildren()) {
      if (targetNodeReached) {
        if (childNode != node) {
          orderMap[childNode.id.toString()] = childNode.order + 1;
          childNode.order = childNode.order + 1;
        }

      } else {
        if (childNode == parent) {
          targetNodeReached = true;
        }
      }
    }
    return orderMap;
  }

  void _addChildToNewParentBackward(Node node, Node newParent) {
    newParent.addAsChild(node);
    for (var i = 1; i <= node.parent!.children.length; i++) {
      if (!(node.parent!.children[i - 1].order == i)) {
        node.parent!.children[i - 1].order = i;
      }
    }
  }

  void _addChildToNewParent(Node node, Node newParent) {
    newParent.addAsChild(node);

  }

  void _makeHttpIndentNodeBackwardRequest(Node node, Node newParent) {
    httpService.httpIndentNodeBackward(node, newParent);
  }

  void _makeHttpSetNodeOrderRequest(Map<String, int> orderMap) {
    httpService.httpSetNodeOrder(orderMap);
  }

  void _sortNodesAndEmitState(
      Node parent, Node newParent, Node node, Emitter<NodeState> emit) {
    parent.sortNodes();
    newParent.sortNodes();
    numberNodes();
    emit(NodeSelectedState(_trees, node));
  }

  //INDENT NODE BACKWARDS END
  //INDENT NODE FORWARD BEGINNING
  FutureOr<void> _onIndentNodeForwardEvent(
      IndentNodeForwardEvent event, Emitter<NodeState> emit) async {
    if (event.node.order > 1) {
      var parent = event.node.parent!;
      Node newParent = parent.getNodeByOrder(event.node.order - 1);
      _makeHttpIndentNodeForwardRequest(event.node, newParent);
      _addChildToNewParent(event.node, newParent);
      Map<String, int> orderMap = _updateNodeOrdersForForwardIndent(event.node, newParent, parent);
      _makeHttpSetNodeOrderRequest(orderMap);
      _sortNodesAndEmitState(parent, newParent, event.node, emit);
    }
  }

  void _makeHttpIndentNodeForwardRequest(Node node, Node newParent) {
    httpService.httpIndentNodeForward(node, newParent);
  }

  Map<String, int> _updateNodeOrdersForForwardIndent(Node node, Node newParent, Node parent) {
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
    return orderMap;
  }

  //INDENT NODE FORWARD END

  // FutureOr<void> _onIndentNodeForwardEvent(
  //     IndentNodeForwardEvent event, Emitter<NodeState> emit) async {
  //   if (event.node.order > 1) {
  //     var parent = event.node.parent!;
  //     Node newParent = parent.getNodeByOrder(event.node.order - 1);
  //
  //     httpService.httpIndentNodeForward(event.node, newParent);
  //
  //     newParent.addAsChild(event.node);
  //
  //     Map<String, int> orderMap = {};
  //     for (var i = 1; i <= newParent.children.length; i++) {
  //       if (!(newParent.children[i - 1].order == i)) {
  //         newParent.children[i - 1].order = i;
  //         orderMap[(newParent.children[i - 1].id).toString()] = i;
  //       }
  //     }
  //     for (var i = 1; i <= parent.getChildren().length; i++) {
  //       if (!(parent.getChildren()[i - 1].order == i)) {
  //         parent.getChildren()[i - 1].order = i;
  //         orderMap[(parent.getChildren()[i - 1].id).toString()] = i;
  //       }
  //     }
  //
  //     httpService.httpSetNodeOrder(orderMap);
  //
  //     parent.sortNodes();
  //     newParent.sortNodes();
  //     numberNodes();
  //
  //     emit(NodeSelectedState(_trees, event.node));
  //   }
  // }



  FutureOr<void> _onLoadTreesEvent(
    LoadTreesEvent event,
    Emitter<NodeState> emit,
  ) async {
    final response = await httpService.httpLoadTrees();
    if (response.statusCode == 200) {
      _trees = parseTreesFromJson(response.body);
      emit(TreesLoadedState(_trees));
      add(NumberNodesEvent(_trees));
    } else {
      emit(ErrorState('Failed to load trees'));
    }
  }

  void _onNumberNodesEvent(
    NumberNodesEvent event,
    Emitter<NodeState> emit,
  ) {
    for (var tree in _trees) {
      _numberNodesRecursive(tree.rootNode.children);
    }
    emit(TreesNumberedState(_trees));
  }

  FutureOr<void> _onNodeSelectedEvent(
    SelectNodeEvent event,
    Emitter<NodeState> emit,
  ) async {
    emit(NodeSelectedState(_trees, event.node));
  }

  FutureOr<void> _onEditNodeEvent(
    EditNodeEvent event,
    Emitter<NodeState> emit,
  ) async {
    emit(EditingNodeState(_trees, event.nodeId));
  }

  FutureOr<void> _onUpdateNodeTextEvent(
    UpdateNodeTextEvent event,
    Emitter<NodeState> emit,
  ) async {
    final response =
        await httpService.httpUpdateNodeText(event.node, event.newText);
    if (response.statusCode == 200) {
      event.node.text = event.newText;
      emit(NodeSelectedState(_trees, event.node));
    } else {
      emit(ErrorState('Failed to update node text'));
    }
  }

  //MOVENODEUP
  FutureOr<void> _onMoveNodeUpEvent(
      MoveNodeUpEvent event,
      Emitter<NodeState> emit,
      ) async {
    Node parent = event.node.parent!;
    if (event.node.order > 1) {
      Node nodeToSwap = parent.getNodeByOrder(event.node.order - 1);

      bool swapSuccessful = await _swapNodeOrders(event.node, nodeToSwap);

      if (swapSuccessful) {
        _sortNodesAndEmitState(parent, parent, event.node, emit);
      } else {
        emit(ErrorState('Failed to move node up'));
      }
    }
  }

  Future<bool> _swapNodeOrders(Node node, Node nodeToSwap) async {
    final responseSwap = await httpService.httpMoveNode(nodeToSwap, node.order);
    final responseCurrent = await httpService.httpMoveNode(node, node.order - 1);

    if (responseSwap.statusCode == 200 && responseCurrent.statusCode == 200) {
      nodeToSwap.order = node.order;
      node.order -= 1;
      return true;
    } else {
      return false;
    }
  }

  //MOVENODEUP//
  //MOVENODEDOWN
  FutureOr<void> _onMoveNodeDownEvent(
      MoveNodeDownEvent event,
      Emitter<NodeState> emit,
      ) async {
    Node parent = event.node.parent!;
    if (event.node.order < parent.children.length) {
      Node nodeToSwap = parent.getNodeByOrder(event.node.order + 1);

      bool swapSuccessful = await _swapNodeOrdersDown(event.node, nodeToSwap);

      if (swapSuccessful) {
        _sortNodesAndEmitState(parent, parent, event.node, emit);
      } else {
        emit(ErrorState('Failed to move node down'));
      }
    }
  }
  //
  Future<bool> _swapNodeOrdersDown(Node node, Node nodeToSwap) async {
    final responseSwap = await httpService.httpMoveNode(nodeToSwap, node.order);
    final responseCurrent = await httpService.httpMoveNode(node, node.order + 1);

    if (responseSwap.statusCode == 200 && responseCurrent.statusCode == 200) {
      nodeToSwap.order = node.order;
      node.order += 1;
      return true;
    } else {
      return false;
    }
  }

//MOVENODEDOWN//
  FutureOr<void> _onDeleteNodeEvent(
    DeleteNodeEvent event,
    Emitter<NodeState> emit,
  ) async {
    dynamic parent = event.node.parent;
    final response = await httpService.httpDeleteNode(event.node);
    print(response.statusCode);
    if (response.statusCode == 204) {
      parent!.removeChild(event.node);
      _updateNodeOrders(parent);
      emit(TreesNumberedState(_trees));
    } else {
      emit(ErrorState('Failed to delete node'));
    }
  }

  void _updateNodeOrders(Node parent) {
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
//ADDNODE
  FutureOr<void> _onAddNodeEvent(
      AddNodeEvent event,
      Emitter<NodeState> emit,
      ) async {
    var order = event.under.parent!.children.length + 1;
    final response = await _addNodeHttpRequest(event.under, event.tree, event.text, order);

    if (response.statusCode == 201) {
      Node new_node = _createNewNode(response, event.text, order, event.under.parent!);
      _updateParentChildRelation(event.under, new_node);
      _sortNodesAndEmitState(event.under, event.under, new_node, emit);
    } else {
      print(response.body);
      emit(ErrorState('Failed to add node'));
    }
  }

  Future<http.Response> _addNodeHttpRequest(Node parent, Tree tree, String text, int order) async {
    return await httpService.httpAddNode(parent, tree, text, order);
  }

  Node _createNewNode(http.Response response, String text, int order, Node parent) {
    var serializedResponse = jsonDecode(response.body);
    return Node(
        id: serializedResponse['id'],
        text: text,
        forwardNodeAssociations: [],
        backwardNodeAssociations: [],
        children: [],
        order: order,
        parent: parent
    );
  }

  void _updateParentChildRelation(Node parent, Node new_node) {
    if (parent.parent != null) {
      parent.parent!.children.add(new_node);
      _updateNodeOrders(parent.parent!);
    } else {
      parent.children.add(new_node);
      _updateNodeOrders(parent);
    }
  }

//ADDNODE//

  Future<http.Response> getTreeOfNode(int nodeId, String url) async {
    return await httpService.getTreeid(nodeId, url);
  }

  Future<List<AssociatedNode>> getForwardAssociationsOfNode(int nodeId) async {
    http.Response response = await httpService.getForwardAssociations(nodeId);
    var serializedResponse = jsonDecode(response.body);
    List<AssociatedNode> associatedNodes = [];
    for (var node in serializedResponse) {
      associatedNodes.add(AssociatedNode(node['id'], node['url']));
    }
    return associatedNodes;
  }

  Future<List<AssociatedNode>> getBackwardAssociationsOfNode(int nodeId) async {
    http.Response response = await httpService.getBackwardAssociations(nodeId);
    var serializedResponse = jsonDecode(response.body);
    List<AssociatedNode> associatedNodes = [];
    for (var node in serializedResponse) {
      associatedNodes.add(AssociatedNode(node['id'], node['url']));
    }
    return associatedNodes;
  }

  void numberNodes() {
    for (var tree in _trees) {
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
    emit(TreesNumberedState(_trees));
  }

  FutureOr<void> _onAssociateNode(
      AssociateNodeEvent event, Emitter<NodeState> emit) async {
    await httpService.associateNode(event.from_node.id, event.to_node.id);
  }

  FutureOr<void> _onUnassociateBackwardEvent(
      UnassociateBackwardEvent event, Emitter<NodeState> emit) {
    httpService.unassociate_backward(event.from_node.id, event.to_node.id);
  }

  FutureOr<void> _onUnassociateForwardEvent(
      UnassociateForwardEvent event, Emitter<NodeState> emit) {
    httpService.unassociate_forward(event.from_node.id, event.to_node.id);
  }
}

