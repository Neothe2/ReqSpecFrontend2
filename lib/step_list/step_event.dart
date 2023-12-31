part of 'step_bloc.dart';

@immutable
abstract class TreeEvent {}

class LoadTreesEvent extends TreeEvent {}

class NumberNodesEvent extends TreeEvent {
  final List<Tree> trees;

  NumberNodesEvent(this.trees);
}

class DeselectNodeEvent extends TreeEvent {}

class SelectNodeEvent extends TreeEvent {
  final Node node;
  SelectNodeEvent(this.node);
}

class AssociateNodeEvent extends TreeEvent {
  final Node from_node;
  final Node to_node;

  AssociateNodeEvent(this.from_node, this.to_node);
}

// Event triggered when the user wants to edit a node
class EditNodeEvent extends TreeEvent {
  final int nodeId;
  EditNodeEvent(this.nodeId);
}

class UnassociateForwardEvent extends TreeEvent {
  final Node from_node;
  final AssociatedNode to_node;

  UnassociateForwardEvent(this.from_node, this.to_node);
}

class UnassociateBackwardEvent extends TreeEvent {
  final AssociatedNode from_node;
  final Node to_node;

  UnassociateBackwardEvent(this.from_node, this.to_node);
}

// Event triggered when the user submits their changes to a node's text
class UpdateNodeTextEvent extends TreeEvent {
  final Node node;
  final String newText;
  UpdateNodeTextEvent(this.node, this.newText);
}

class MoveNodeUpEvent extends TreeEvent {
  final Node node;
  MoveNodeUpEvent(this.node);
}

class MoveNodeDownEvent extends TreeEvent {
  final Node node;
  MoveNodeDownEvent(this.node);
}

class IndentNodeForwardEvent extends TreeEvent {
  final Node node;
  IndentNodeForwardEvent(this.node);
}

class IndentNodeBackwardEvent extends TreeEvent {
  final Node node;
  IndentNodeBackwardEvent(this.node);
}

class DeleteNodeEvent extends TreeEvent {
  final Node node;
  DeleteNodeEvent(this.node);
}

class AddNodeEvent extends TreeEvent {
  final String text;
  final Node under;
  final Tree tree;

  AddNodeEvent(this.text, this.under, this.tree);
}
