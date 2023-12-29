part of 'step_bloc.dart';

@immutable
abstract class NodeState {}

class InitialNodeState extends NodeState {}

class TreesLoadedState extends NodeState {
  final List<Tree> trees;

  TreesLoadedState(this.trees);
}

class TreesNumberedState extends NodeState {
  final List<Tree> trees;

  TreesNumberedState(this.trees);
}

class ErrorState extends NodeState {
  final String message;

  ErrorState(this.message);
}

class NodeSelectedState extends NodeState {
  final List<Tree> trees;
  final Node selectedNode;

  NodeSelectedState(this.trees, this.selectedNode);
}

class EditingNodeState extends NodeState {
  final List<Tree> trees;
  final int editingNodeId;
  EditingNodeState(this.trees, this.editingNodeId);
}
