import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class TvFocusTraversalPolicy extends FocusTraversalPolicy {
  TvFocusTraversalPolicy({super.requestFocusCallback});

  final FocusTraversalPolicy _readingOrder = ReadingOrderTraversalPolicy();
  final Map<FocusScopeNode, _TvDirectionalPolicyData> _policyData =
      <FocusScopeNode, _TvDirectionalPolicyData>{};

  @override
  Iterable<FocusNode> sortDescendants(
          Iterable<FocusNode> descendants, FocusNode currentNode) =>
      _readingOrder.sortDescendants(descendants, currentNode);

  @override
  void invalidateScopeData(FocusScopeNode node) {
    super.invalidateScopeData(node);
    _policyData.remove(node);
  }

  @override
  void changedScope({FocusNode? node, FocusScopeNode? oldScope}) {
    super.changedScope(node: node, oldScope: oldScope);
    if (oldScope != null) {
      _policyData[oldScope]?.history
          .removeWhere((_TvDirectionalPolicyDataEntry entry) {
        return entry.node == node;
      });
    }
  }

  @override
  FocusNode? findFirstFocusInDirection(
      FocusNode currentNode, TraversalDirection direction) {
    final Iterable<FocusNode> nodes =
        currentNode.nearestScope!.traversalDescendants;
    final List<FocusNode> sorted = nodes.toList();
    final (bool vertical, bool first) = switch (direction) {
      TraversalDirection.up => (true, false),
      TraversalDirection.down => (true, true),
      TraversalDirection.left => (false, false),
      TraversalDirection.right => (false, true),
    };
    mergeSort<FocusNode>(sorted, compare: (FocusNode a, FocusNode b) {
      if (vertical) {
        if (first) {
          return a.rect.top.compareTo(b.rect.top);
        }
        return b.rect.bottom.compareTo(a.rect.bottom);
      }
      if (first) {
        return a.rect.left.compareTo(b.rect.left);
      }
      return b.rect.right.compareTo(a.rect.right);
    });

    return sorted.firstOrNull;
  }

  static int _verticalCompare(Offset target, Offset a, Offset b) {
    return (a.dy - target.dy).abs().compareTo((b.dy - target.dy).abs());
  }

  static int _horizontalCompare(Offset target, Offset a, Offset b) {
    return (a.dx - target.dx).abs().compareTo((b.dx - target.dx).abs());
  }

  static Iterable<FocusNode> _sortByDistancePreferVertical(
      Offset target, Iterable<FocusNode> nodes) {
    final List<FocusNode> sorted = nodes.toList();
    mergeSort<FocusNode>(sorted, compare: (FocusNode nodeA, FocusNode nodeB) {
      final Offset a = nodeA.rect.center;
      final Offset b = nodeB.rect.center;
      final int vertical = _verticalCompare(target, a, b);
      if (vertical == 0) {
        return _horizontalCompare(target, a, b);
      }
      return vertical;
    });
    return sorted;
  }

  static Iterable<FocusNode> _sortByDistancePreferHorizontal(
      Offset target, Iterable<FocusNode> nodes) {
    final List<FocusNode> sorted = nodes.toList();
    mergeSort<FocusNode>(sorted, compare: (FocusNode nodeA, FocusNode nodeB) {
      final Offset a = nodeA.rect.center;
      final Offset b = nodeB.rect.center;
      final int horizontal = _horizontalCompare(target, a, b);
      if (horizontal == 0) {
        return _verticalCompare(target, a, b);
      }
      return horizontal;
    });
    return sorted;
  }

  static int _verticalCompareClosestEdge(Offset target, Rect a, Rect b) {
    final double aCoord =
        (a.top - target.dy).abs() < (a.bottom - target.dy).abs()
            ? a.top
            : a.bottom;
    final double bCoord =
        (b.top - target.dy).abs() < (b.bottom - target.dy).abs()
            ? b.top
            : b.bottom;
    return (aCoord - target.dy).abs().compareTo((bCoord - target.dy).abs());
  }

  static int _horizontalCompareClosestEdge(Offset target, Rect a, Rect b) {
    final double aCoord =
        (a.left - target.dx).abs() < (a.right - target.dx).abs()
            ? a.left
            : a.right;
    final double bCoord =
        (b.left - target.dx).abs() < (b.right - target.dx).abs()
            ? b.left
            : b.right;
    return (aCoord - target.dx).abs().compareTo((bCoord - target.dx).abs());
  }

  static Iterable<FocusNode> _sortClosestEdgesByDistancePreferHorizontal(
      Offset target, Iterable<FocusNode> nodes) {
    final List<FocusNode> sorted = nodes.toList();
    mergeSort<FocusNode>(sorted, compare: (FocusNode nodeA, FocusNode nodeB) {
      final int horizontal =
          _horizontalCompareClosestEdge(target, nodeA.rect, nodeB.rect);
      if (horizontal == 0) {
        return _verticalCompare(target, nodeA.rect.center, nodeB.rect.center);
      }
      return horizontal;
    });
    return sorted;
  }

  static Iterable<FocusNode> _sortClosestEdgesByDistancePreferVertical(
      Offset target, Iterable<FocusNode> nodes) {
    final List<FocusNode> sorted = nodes.toList();
    mergeSort<FocusNode>(sorted, compare: (FocusNode nodeA, FocusNode nodeB) {
      final int vertical =
          _verticalCompareClosestEdge(target, nodeA.rect, nodeB.rect);
      if (vertical == 0) {
        return _horizontalCompare(target, nodeA.rect.center, nodeB.rect.center);
      }
      return vertical;
    });
    return sorted;
  }

  Iterable<FocusNode> _sortAndFilterHorizontally(
    TraversalDirection direction,
    Rect target,
    Iterable<FocusNode> nodes,
  ) {
    assert(direction == TraversalDirection.left ||
        direction == TraversalDirection.right);
    final List<FocusNode> sorted = nodes.where(switch (direction) {
      TraversalDirection.left =>
        (FocusNode node) => node.rect != target && node.rect.center.dx <= target.left,
      TraversalDirection.right =>
        (FocusNode node) => node.rect != target && node.rect.center.dx >= target.right,
      TraversalDirection.up || TraversalDirection.down =>
        throw ArgumentError('Invalid direction $direction'),
    }).toList();
    mergeSort<FocusNode>(sorted,
        compare: (FocusNode a, FocusNode b) =>
            a.rect.center.dx.compareTo(b.rect.center.dx));
    return sorted;
  }

  Iterable<FocusNode> _sortAndFilterVertically(
    TraversalDirection direction,
    Rect target,
    Iterable<FocusNode> nodes,
  ) {
    assert(direction == TraversalDirection.up ||
        direction == TraversalDirection.down);
    final List<FocusNode> sorted = nodes.where(switch (direction) {
      TraversalDirection.up =>
        (FocusNode node) => node.rect != target && node.rect.center.dy <= target.top,
      TraversalDirection.down =>
        (FocusNode node) => node.rect != target && node.rect.center.dy >= target.bottom,
      TraversalDirection.left || TraversalDirection.right =>
        throw ArgumentError('Invalid direction $direction'),
    }).toList();
    mergeSort<FocusNode>(sorted,
        compare: (FocusNode a, FocusNode b) =>
            a.rect.center.dy.compareTo(b.rect.center.dy));
    return sorted;
  }

  bool _popPolicyDataIfNeeded(
    TraversalDirection direction,
    FocusScopeNode nearestScope,
    FocusNode focusedChild,
  ) {
    final _TvDirectionalPolicyData? policyData = _policyData[nearestScope];
    if (policyData != null &&
        policyData.history.isNotEmpty &&
        policyData.history.first.direction != direction) {
      if (policyData.history.last.node.parent == null) {
        invalidateScopeData(nearestScope);
        return false;
      }

      bool popOrInvalidate(TraversalDirection direction) {
        final FocusNode lastNode = policyData.history.removeLast().node;
        if (Scrollable.maybeOf(lastNode.context!) !=
            Scrollable.maybeOf(primaryFocus!.context!)) {
          invalidateScopeData(nearestScope);
          return false;
        }
        final ScrollPositionAlignmentPolicy alignmentPolicy;
        switch (direction) {
          case TraversalDirection.up:
          case TraversalDirection.left:
            alignmentPolicy = ScrollPositionAlignmentPolicy.keepVisibleAtStart;
          case TraversalDirection.right:
          case TraversalDirection.down:
            alignmentPolicy = ScrollPositionAlignmentPolicy.keepVisibleAtEnd;
        }
        requestFocusCallback(
          lastNode,
          alignmentPolicy: alignmentPolicy,
        );
        return true;
      }

      switch (direction) {
        case TraversalDirection.down:
        case TraversalDirection.up:
          switch (policyData.history.first.direction) {
            case TraversalDirection.left:
            case TraversalDirection.right:
              invalidateScopeData(nearestScope);
            case TraversalDirection.up:
            case TraversalDirection.down:
              if (popOrInvalidate(direction)) {
                return true;
              }
          }
        case TraversalDirection.left:
        case TraversalDirection.right:
          switch (policyData.history.first.direction) {
            case TraversalDirection.left:
            case TraversalDirection.right:
              if (popOrInvalidate(direction)) {
                return true;
              }
            case TraversalDirection.up:
            case TraversalDirection.down:
              invalidateScopeData(nearestScope);
          }
      }
    }
    if (policyData != null && policyData.history.isEmpty) {
      invalidateScopeData(nearestScope);
    }
    return false;
  }

  void _pushPolicyData(
    TraversalDirection direction,
    FocusScopeNode nearestScope,
    FocusNode focusedChild,
  ) {
    final _TvDirectionalPolicyData? policyData = _policyData[nearestScope];
    final _TvDirectionalPolicyDataEntry newEntry =
        _TvDirectionalPolicyDataEntry(
            node: focusedChild, direction: direction);
    if (policyData != null) {
      policyData.history.add(newEntry);
    } else {
      _policyData[nearestScope] =
          _TvDirectionalPolicyData(history: <_TvDirectionalPolicyDataEntry>[
        newEntry
      ]);
    }
  }

  @override
  bool inDirection(FocusNode currentNode, TraversalDirection direction) {
    final FocusScopeNode nearestScope = currentNode.nearestScope!;
    final FocusNode? focusedChild = nearestScope.focusedChild;
    if (focusedChild == null) {
      final FocusNode firstFocus =
          findFirstFocusInDirection(currentNode, direction) ?? currentNode;
      switch (direction) {
        case TraversalDirection.up:
        case TraversalDirection.left:
          requestFocusCallback(
            firstFocus,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
        case TraversalDirection.right:
        case TraversalDirection.down:
          requestFocusCallback(
            firstFocus,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
      }
      return true;
    }
    if (_popPolicyDataIfNeeded(direction, nearestScope, focusedChild)) {
      return true;
    }
    FocusNode? found;
    final ScrollableState? focusedScrollable =
        Scrollable.maybeOf(focusedChild.context!);
    final Axis? focusedAxis = focusedScrollable?.position.axis;
    final bool shouldRestrictToScrollable = focusedScrollable != null &&
        !focusedScrollable.position.atEdge &&
        ((direction == TraversalDirection.up ||
                direction == TraversalDirection.down)
            ? focusedAxis == Axis.vertical
            : focusedAxis == Axis.horizontal);

    switch (direction) {
      case TraversalDirection.down:
      case TraversalDirection.up:
        Iterable<FocusNode> eligibleNodes = _sortAndFilterVertically(
            direction, focusedChild.rect, nearestScope.traversalDescendants);
        if (eligibleNodes.isEmpty) {
          break;
        }
        if (shouldRestrictToScrollable) {
          final Iterable<FocusNode> filteredEligibleNodes = eligibleNodes.where(
              (FocusNode node) =>
                  Scrollable.maybeOf(node.context!) == focusedScrollable);
          if (filteredEligibleNodes.isNotEmpty) {
            eligibleNodes = filteredEligibleNodes;
          }
        }
        if (direction == TraversalDirection.up) {
          eligibleNodes = eligibleNodes.toList().reversed;
        }
        final Rect band = Rect.fromLTRB(
            focusedChild.rect.left,
            -double.infinity,
            focusedChild.rect.right,
            double.infinity);
        final Iterable<FocusNode> inBand = eligibleNodes
            .where((FocusNode node) => !node.rect.intersect(band).isEmpty);
        if (inBand.isNotEmpty) {
          found = _sortByDistancePreferVertical(
                  focusedChild.rect.center, inBand)
              .first;
          break;
        }
        found = _sortClosestEdgesByDistancePreferHorizontal(
                focusedChild.rect.center, eligibleNodes)
            .first;
      case TraversalDirection.right:
      case TraversalDirection.left:
        Iterable<FocusNode> eligibleNodes = _sortAndFilterHorizontally(
            direction, focusedChild.rect, nearestScope.traversalDescendants);
        if (eligibleNodes.isEmpty) {
          break;
        }
        if (shouldRestrictToScrollable) {
          final Iterable<FocusNode> filteredEligibleNodes = eligibleNodes.where(
              (FocusNode node) =>
                  Scrollable.maybeOf(node.context!) == focusedScrollable);
          if (filteredEligibleNodes.isNotEmpty) {
            eligibleNodes = filteredEligibleNodes;
          }
        }
        if (direction == TraversalDirection.left) {
          eligibleNodes = eligibleNodes.toList().reversed;
        }
        final Rect band = Rect.fromLTRB(-double.infinity,
            focusedChild.rect.top, double.infinity, focusedChild.rect.bottom);
        final Iterable<FocusNode> inBand = eligibleNodes
            .where((FocusNode node) => !node.rect.intersect(band).isEmpty);
        if (inBand.isNotEmpty) {
          found = _sortByDistancePreferHorizontal(
                  focusedChild.rect.center, inBand)
              .first;
          break;
        }
        found = _sortClosestEdgesByDistancePreferVertical(
                focusedChild.rect.center, eligibleNodes)
            .first;
    }
    if (found != null) {
      _pushPolicyData(direction, nearestScope, focusedChild);
      switch (direction) {
        case TraversalDirection.up:
        case TraversalDirection.left:
          requestFocusCallback(
            found,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtStart,
          );
        case TraversalDirection.down:
        case TraversalDirection.right:
          requestFocusCallback(
            found,
            alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
          );
      }
      return true;
    }
    return false;
  }
}

class _TvDirectionalPolicyData {
  _TvDirectionalPolicyData({required this.history});

  final List<_TvDirectionalPolicyDataEntry> history;
}

class _TvDirectionalPolicyDataEntry {
  _TvDirectionalPolicyDataEntry({
    required this.node,
    required this.direction,
  });

  final FocusNode node;
  final TraversalDirection direction;
}
