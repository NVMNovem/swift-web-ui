/// A positional location in the mounted runtime tree.
///
/// A path describes traversal through element and fragment children. It is not
/// stable semantic identity and must not be used to preserve identity across
/// reordering.
struct NodePath: Hashable, Sendable {
    var indices: [Int]

    init(_ indices: [Int] = []) {
        self.indices = indices
    }

    func appending(_ index: Int) -> NodePath {
        NodePath(indices + [index])
    }
}
