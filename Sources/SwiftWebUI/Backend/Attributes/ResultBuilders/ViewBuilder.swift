//
//  ViewBuilder.swift
//  swift-web-ui
//
//  Created by Damian Van de Kauter on 23/06/2026.
//

/// Builds statically typed SwiftWebUI content without view erasure.
@resultBuilder
public enum ViewBuilder {
    public static func buildExpression<Content: View>(_ expression: Content) -> Content {
        expression
    }

    public static func buildExpression<Content: View>(
        _ expressions: [Content]
    ) -> ArrayView<Content> {
        ArrayView(expressions)
    }

    public static func buildBlock() -> EmptyView {
        EmptyView()
    }

    public static func buildBlock<Content: View>(_ content: Content) -> Content {
        content
    }

    public static func buildBlock<C0: View, C1: View>(
        _ c0: C0,
        _ c1: C1
    ) -> TupleView2<C0, C1> {
        TupleView2(c0, c1)
    }

    public static func buildBlock<C0: View, C1: View, C2: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2
    ) -> TupleView3<C0, C1, C2> {
        TupleView3(c0, c1, c2)
    }

    public static func buildBlock<C0: View, C1: View, C2: View, C3: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3
    ) -> TupleView4<C0, C1, C2, C3> {
        TupleView4(c0, c1, c2, c3)
    }

    public static func buildBlock<C0: View, C1: View, C2: View, C3: View, C4: View>(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4
    ) -> TupleView5<C0, C1, C2, C3, C4> {
        TupleView5(c0, c1, c2, c3, c4)
    }

    public static func buildBlock<
        C0: View,
        C1: View,
        C2: View,
        C3: View,
        C4: View,
        C5: View
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5
    ) -> TupleView6<C0, C1, C2, C3, C4, C5> {
        TupleView6(c0, c1, c2, c3, c4, c5)
    }

    public static func buildBlock<
        C0: View,
        C1: View,
        C2: View,
        C3: View,
        C4: View,
        C5: View,
        C6: View
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6
    ) -> TupleView7<C0, C1, C2, C3, C4, C5, C6> {
        TupleView7(c0, c1, c2, c3, c4, c5, c6)
    }

    public static func buildBlock<
        C0: View,
        C1: View,
        C2: View,
        C3: View,
        C4: View,
        C5: View,
        C6: View,
        C7: View
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7
    ) -> TupleView8<C0, C1, C2, C3, C4, C5, C6, C7> {
        TupleView8(c0, c1, c2, c3, c4, c5, c6, c7)
    }

    public static func buildBlock<
        C0: View,
        C1: View,
        C2: View,
        C3: View,
        C4: View,
        C5: View,
        C6: View,
        C7: View,
        C8: View
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7,
        _ c8: C8
    ) -> TupleView9<C0, C1, C2, C3, C4, C5, C6, C7, C8> {
        TupleView9(c0, c1, c2, c3, c4, c5, c6, c7, c8)
    }

    public static func buildBlock<
        C0: View,
        C1: View,
        C2: View,
        C3: View,
        C4: View,
        C5: View,
        C6: View,
        C7: View,
        C8: View,
        C9: View
    >(
        _ c0: C0,
        _ c1: C1,
        _ c2: C2,
        _ c3: C3,
        _ c4: C4,
        _ c5: C5,
        _ c6: C6,
        _ c7: C7,
        _ c8: C8,
        _ c9: C9
    ) -> TupleView10<C0, C1, C2, C3, C4, C5, C6, C7, C8, C9> {
        TupleView10(c0, c1, c2, c3, c4, c5, c6, c7, c8, c9)
    }

    public static func buildOptional<Content: View>(
        _ component: Content?
    ) -> OptionalView<Content> {
        OptionalView(component)
    }

    public static func buildEither<TrueContent: View, FalseContent: View>(
        first component: TrueContent
    ) -> ConditionalView<TrueContent, FalseContent> {
        ConditionalView(storage: .trueContent(component))
    }

    public static func buildEither<TrueContent: View, FalseContent: View>(
        second component: FalseContent
    ) -> ConditionalView<TrueContent, FalseContent> {
        ConditionalView(storage: .falseContent(component))
    }

    public static func buildArray<Content: View>(
        _ components: [Content]
    ) -> ArrayView<Content> {
        ArrayView(components)
    }
}
