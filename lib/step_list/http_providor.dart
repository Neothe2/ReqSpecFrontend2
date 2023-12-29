import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class TreeHttpProvider {
  var url = 'http://192.168.0.4:8000/reqspec';
  var treesRoute = '/trees';
  var nodesRoute = '/nodes';

  Future<http.Response> httpIndentNodeBackward(
      Node node, dynamic newParent) async {
    var requestBody = {
      "parent": newParent.id,
      "id": node.id,
    };

    return await http.patch(Uri.parse('${url}/reqspec/nodes/${node.id}/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody));
  }

  Future<http.Response> associateNode(int from_node_id, int to_node_id) async {
    var requestBody = {
      "id": to_node_id,
    };

    return await http.post(Uri.parse('${url + nodesRoute}/${from_node_id}/associate_node/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody));
  }


  Future<http.Response> httpIndentNodeForward(Node node, Node newParent) async {
    var requestBody = {
      "parent": newParent.id,
      "id": node.id,
    };

    return await http.patch(Uri.parse('${url}/reqspec/nodes/${node.id}/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody));
  }

  Future<http.Response> httpLoadTrees() async {
    return await http.get(Uri.parse('${url}/trees/'));
  }

  Future<http.Response> httpUpdateNodeText(Node node, String newText) async {
    return await http
        .patch(Uri.parse('${url}/nodes/${node.id}/'), body: {"text": newText});
  }

  Future<http.Response> httpMoveNode(Node node, int newOrder) async {
    return await http.patch(Uri.parse('${url}/nodes/${node.id}/'),
        body: {'order': newOrder.toString()});
  }

  Future<http.Response> httpDeleteNode(Node node) async {
    return await http.delete(Uri.parse('${url}/nodes/${node.id}/'));
  }

  Future<http.Response> httpAddNode(
      Node under, Tree tree, String text, int order) async {
    // Tree tree;
    // while (true) {
    //   if (under.parent)
    // }
    return await http.post(Uri.parse('${url}/trees/${tree.id}/create_node/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text, "order": order}));
  }

  Future<http.Response> httpSetNodeOrder(Map<String, int> orderMap) async {
    return await http.post(Uri.parse('${url}/nodes/set_order/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(orderMap));
  }

  Future<http.Response> getTreeid(int nodeId, String nodesUrl) async {
    return http.get(Uri.parse('${'$url/$nodesUrl'}/${nodeId}/get_tree_id/'));
  }
}

class StepHttpProvider extends TreeHttpProvider {
  @override
  var url = 'http://10.0.2.2:8000/reqspec';
  @override
  var treesRoute = '/main_flows';
  @override
  var nodesRoute = '/main_flow_steps';

  @override
  Future<http.Response> httpIndentNodeBackward(
      Node node, dynamic newParent) async {
    var requestBody = {
      "parent": newParent.id,
      "id": node.id,
    };
    print('Syke');

    return await http.patch(Uri.parse('${url + nodesRoute}/${node.id}/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody));
  }

  @override
  Future<http.Response> httpIndentNodeForward(Node node, Node newParent) async {
    var requestBody = {
      "parent": newParent.id,
      "id": node.id,
    };

    print('Syke');
    return await http.patch(Uri.parse('${url + nodesRoute}/${node.id}/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody));
  }

  @override
  Future<http.Response> httpLoadTrees() async {
    print('Syke');
    return await http.get(Uri.parse('${url + treesRoute}/'));
  }

  @override
  Future<http.Response> httpUpdateNodeText(Node node, String newText) async {
    //TODO change the parsing logic to turn "data" into "text"
    print('Syke');
    return await http.patch(Uri.parse('${url + nodesRoute}/${node.id}/'),
        body: {"data": newText});
  }

  @override
  Future<http.Response> httpMoveNode(Node node, int newOrder) async {
    print('Syke');
    return await http.patch(Uri.parse('${url + nodesRoute}/${node.id}/'),
        body: {'order': newOrder.toString()});
  }

  @override
  Future<http.Response> httpDeleteNode(Node node) async {
    print('Syke');
    return await http.delete(Uri.parse('${url + nodesRoute}/${node.id}/'));
  }

  @override
  Future<http.Response> httpAddNode(
      Node under, Tree tree, String text, int order) async {
    // print(jsonEncode({
    //   "under": under.parent!.id,
    //   "node": {"data": text, "order": order}
    // }));
    if (under.parent != null) {
      return await http.post(
          Uri.parse('${url + treesRoute}/${tree.id}/add_node/'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "under": under.parent!.id,
            "node": {"data": text, "order": order}
          }));
    } else {
      return await http.post(
          Uri.parse('${url + treesRoute}/${tree.id}/add_node/'),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode({
            "under": under.id,
            "node": {"data": text, "order": order}
          }));
    }
  }

  @override
  Future<http.Response> httpSetNodeOrder(Map<String, int> orderMap) async {
    print('Syke');
    return await http.post(Uri.parse('${url + nodesRoute}/set_order/'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(orderMap));
  }
}

class AlternateFlowHttpProvidor extends StepHttpProvider {
  @override
  String get treesRoute => '/alternate_flows';

  @override
  String get nodesRoute => '/alternate_flow_steps';
}

class ExceptionFlowHttpProvidor extends StepHttpProvider {
  @override
  String get treesRoute => '/exception_flows';

  @override
  String get nodesRoute => '/exception_flow_steps';
}
