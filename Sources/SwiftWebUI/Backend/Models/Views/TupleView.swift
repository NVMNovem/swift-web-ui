//
//  TupleView.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 20/07/2026.
//

public struct TupleView2<C0: View, C1: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public init(_ c0: C0, _ c1: C1) { self.c0 = c0; self.c1 = c1 }
    public var body: Never { fatalError("TupleView2 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode()]) }
}

public struct TupleView3<C0: View, C1: View, C2: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public let c2: C2
    public init(_ c0: C0, _ c1: C1, _ c2: C2) { self.c0 = c0; self.c1 = c1; self.c2 = c2 }
    public var body: Never { fatalError("TupleView3 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode(), c2.makeViewNode()]) }
}

public struct TupleView4<C0: View, C1: View, C2: View, C3: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public let c2: C2
    public let c3: C3
    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3) { self.c0 = c0; self.c1 = c1; self.c2 = c2; self.c3 = c3 }
    public var body: Never { fatalError("TupleView4 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode(), c2.makeViewNode(), c3.makeViewNode()]) }
}

public struct TupleView5<C0: View, C1: View, C2: View, C3: View, C4: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public let c2: C2
    public let c3: C3
    public let c4: C4
    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4) { self.c0 = c0; self.c1 = c1; self.c2 = c2; self.c3 = c3; self.c4 = c4 }
    public var body: Never { fatalError("TupleView5 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode(), c2.makeViewNode(), c3.makeViewNode(), c4.makeViewNode()]) }
}

public struct TupleView6<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public let c2: C2
    public let c3: C3
    public let c4: C4
    public let c5: C5
    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5) { self.c0 = c0; self.c1 = c1; self.c2 = c2; self.c3 = c3; self.c4 = c4; self.c5 = c5 }
    public var body: Never { fatalError("TupleView6 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode(), c2.makeViewNode(), c3.makeViewNode(), c4.makeViewNode(), c5.makeViewNode()]) }
}

public struct TupleView7<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public let c2: C2
    public let c3: C3
    public let c4: C4
    public let c5: C5
    public let c6: C6
    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6) { self.c0 = c0; self.c1 = c1; self.c2 = c2; self.c3 = c3; self.c4 = c4; self.c5 = c5; self.c6 = c6 }
    public var body: Never { fatalError("TupleView7 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode(), c2.makeViewNode(), c3.makeViewNode(), c4.makeViewNode(), c5.makeViewNode(), c6.makeViewNode()]) }
}

public struct TupleView8<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public let c2: C2
    public let c3: C3
    public let c4: C4
    public let c5: C5
    public let c6: C6
    public let c7: C7
    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7) { self.c0 = c0; self.c1 = c1; self.c2 = c2; self.c3 = c3; self.c4 = c4; self.c5 = c5; self.c6 = c6; self.c7 = c7 }
    public var body: Never { fatalError("TupleView8 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode(), c2.makeViewNode(), c3.makeViewNode(), c4.makeViewNode(), c5.makeViewNode(), c6.makeViewNode(), c7.makeViewNode()]) }
}

public struct TupleView9<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public let c2: C2
    public let c3: C3
    public let c4: C4
    public let c5: C5
    public let c6: C6
    public let c7: C7
    public let c8: C8
    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8) { self.c0 = c0; self.c1 = c1; self.c2 = c2; self.c3 = c3; self.c4 = c4; self.c5 = c5; self.c6 = c6; self.c7 = c7; self.c8 = c8 }
    public var body: Never { fatalError("TupleView9 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode(), c2.makeViewNode(), c3.makeViewNode(), c4.makeViewNode(), c5.makeViewNode(), c6.makeViewNode(), c7.makeViewNode(), c8.makeViewNode()]) }
}

public struct TupleView10<C0: View, C1: View, C2: View, C3: View, C4: View, C5: View, C6: View, C7: View, C8: View, C9: View>: View {
    public typealias Body = Never
    public let c0: C0
    public let c1: C1
    public let c2: C2
    public let c3: C3
    public let c4: C4
    public let c5: C5
    public let c6: C6
    public let c7: C7
    public let c8: C8
    public let c9: C9
    public init(_ c0: C0, _ c1: C1, _ c2: C2, _ c3: C3, _ c4: C4, _ c5: C5, _ c6: C6, _ c7: C7, _ c8: C8, _ c9: C9) { self.c0 = c0; self.c1 = c1; self.c2 = c2; self.c3 = c3; self.c4 = c4; self.c5 = c5; self.c6 = c6; self.c7 = c7; self.c8 = c8; self.c9 = c9 }
    public var body: Never { fatalError("TupleView10 primitive body unavailable") }
    public func makeViewNode() -> ViewNode { .group([c0.makeViewNode(), c1.makeViewNode(), c2.makeViewNode(), c3.makeViewNode(), c4.makeViewNode(), c5.makeViewNode(), c6.makeViewNode(), c7.makeViewNode(), c8.makeViewNode(), c9.makeViewNode()]) }
}
