import Foundation
import GraphQL

public final class ComponentsInitializer<RootType : Keyable, Context> {
    var components: [Component<RootType, Context>] = []
    
    @discardableResult
    public func `enum`<EnumType : Enumerable>(
        _ type: EnumType.Type,
        name: String? = nil,
        build: (ValuesInitializer<RootType, Context, EnumType>) -> ()
    ) -> ComponentInitializer<RootType, Context> {
        let initializer = ValuesInitializer<RootType, Context, EnumType>()
        build(initializer)
        
        let component = Enum<RootType, Context, EnumType>(
            type: type,
            name: name,
            values: initializer.values
        )
        
        components.append(component)
        return ComponentInitializer(component)
    }
    
    public func types(_ types: Any.Type...) {
        let component = Types<RootType, Context>(types)
        components.append(component)
    }
    
    @discardableResult
    public func union<UnionType>(
        _ type: UnionType.Type,
        name: String? = nil,
        members: Any.Type...
    ) -> ComponentInitializer<RootType, Context> {
        let component = Union<RootType, Context, UnionType>(
            type: type,
            name: name,
            members: members
        )
        
        components.append(component)
        return ComponentInitializer(component)
    }
    
    @discardableResult
    public func query(
        name: String = "Query",
        build: (FieldsInitializer<RootType, RootType.Keys, Context>) -> ()
    ) -> ComponentInitializer<RootType, Context> {
        let initializer = FieldsInitializer<RootType, RootType.Keys, Context>()
        build(initializer)

        let component = Query<RootType, Context>(
            name: name,
            fields: initializer.fields
        )

        components.append(component)
        return ComponentInitializer(component)
    }
    
    @discardableResult
    public func mutation(
        name: String = "Mutation",
        build: (FieldsInitializer<RootType, RootType.Keys, Context>) -> ()
    ) -> ComponentInitializer<RootType, Context> {
        let initializer = FieldsInitializer<RootType, RootType.Keys, Context>()
        build(initializer)

        let component = Mutation<RootType, Context>(
            name: name,
            fields: initializer.fields
        )

        components.append(component)
        return ComponentInitializer(component)
    }
    
    @discardableResult
    public func subscription(
        name: String = "Subscription",
        build: (FieldsInitializer<RootType, RootType.Keys, Context>) -> ()
    ) -> ComponentInitializer<RootType, Context> {
        let initializer = FieldsInitializer<RootType, RootType.Keys, Context>()
        build(initializer)

        let component = Subscription<RootType, Context>(
            name: name,
            fields: initializer.fields
        )

        components.append(component)
        return ComponentInitializer(component)
    }
    
    @discardableResult
    public func interface<Reference : InterfaceReference>(
        _ type: Reference.Type,
        name: String? = nil,
        build: (FieldsInitializer<Reference.InterfaceType, Reference.Keys, Context>) -> ()
    ) -> ComponentInitializer<RootType, Context> {
        let initializer = FieldsInitializer<Reference.InterfaceType, Reference.Keys, Context>()
        build(initializer)

        let component = Interface<RootType, Context, Reference>(
            type: type,
            name: name,
            fields: initializer.fields
        )

        components.append(component)
        return ComponentInitializer(component)
    }
    
    @discardableResult
    public func input<InputObjectType : Decodable & Keyable>(
        _ type: InputObjectType.Type,
        name: String? = nil,
        build: (InputFieldsInitializer<InputObjectType, InputObjectType.Keys, Context>) -> ()
    ) -> ComponentInitializer<RootType, Context> {
        let initializer = InputFieldsInitializer<InputObjectType, InputObjectType.Keys, Context>()
        build(initializer)

        let component = Input<RootType, Context, InputObjectType>(
            type: type,
            name: name,
            fields: initializer.fields
        )

        components.append(component)
        return ComponentInitializer(component)
    }
    
    @discardableResult
    public func type<ObjectType : Encodable & Keyable>(
        _ type: ObjectType.Type,
        name: String? = nil,
        interfaces: Any.Type...,
        build: (FieldsInitializer<ObjectType, ObjectType.Keys, Context>) -> ()
    ) -> ComponentInitializer<RootType, Context> {
        let initializer = FieldsInitializer<ObjectType, ObjectType.Keys, Context>()
        build(initializer)

        let component = Type<RootType, Context, ObjectType>(
            type: type,
            name: name,
            interfaces: interfaces,
            fields: initializer.fields
        )

        components.append(component)
        return ComponentInitializer(component)
    }
    
    @discardableResult
    public func scalar<ScalarType : Codable>(
        _ type: ScalarType.Type,
        name: String? = nil,
        serialize: ((ScalarType) throws -> Map)? = nil,
        parse: ((Map) throws -> ScalarType)? = nil
    ) -> ComponentInitializer<RootType, Context> {
        let component = Scalar<RootType, Context, ScalarType>(
            type: type,
            name: name,
            serialize: serialize,
            parse: parse
        )
        
        components.append(component)
        return ComponentInitializer(component)
    }
    
    // MARK: Extensions
    
    public func connection<ObjectType : Encodable & Keyable>(
        _ type: ObjectType.Type,
        name: String? = nil
    ) {
        if !components.contains(where: { $0.name == "PageInfo" }) {
            self.type(PageInfo.self) { type in
                type.field(.hasPreviousPage, at: \.hasPreviousPage)
                type.field(.hasNextPage, at: \.hasNextPage)
                type.field(.startCursor, at: \.startCursor)
                type.field(.endCursor, at: \.endCursor)
            }
        }
        
        self.type(Edge<ObjectType>.self) { type in
            type.field(.node, at: \.node)
            type.field(.cursor, at: \.cursor)
        }
        
        self.type(Connection<ObjectType>.self) { type in
            type.field(.edges, at: \.edges)
            type.field(.pageInfo, at: \.pageInfo)
        }
    }
    
    @discardableResult
    public func dateScalar(
        formatter: DateFormatter,
        name: String? = nil
    ) -> ComponentInitializer<RootType, Context> {
        scalar(
            Date.self,
            name: name,
            serialize: { date in
                .string(formatter.string(from: date))
            },
            parse: { map in
                guard let string = map.string else {
                    throw GraphQLError(message: "Invalid type for Date scalar. Expected string, but got \(map.typeDescription)")
                }
                
                guard let date = formatter.date(from: string) else {
                    throw GraphQLError(message: "Invalid date string for Date scalar.")
                }
                
                return date
            }
        )
    }
    
    @discardableResult
    public func urlScalar(
        name: String? = nil
    ) -> ComponentInitializer<RootType, Context> {
        scalar(
            URL.self,
            name: name,
            serialize: { url in
                .string(url.absoluteString)
            },
            parse: { map in
                guard let string = map.string else {
                    throw GraphQLError(message: "Invalid type for URL scalar. Expected string, but got \(map.typeDescription)")
                }
                
                guard let url = URL(string: string) else {
                    throw GraphQLError(message: "Invalid url string for URL scalar.")
                }
                
                return url
            }
        )
    }
    
    @discardableResult
    public func uuidScalar(
        name: String? = nil
    ) -> ComponentInitializer<RootType, Context> {
        scalar(
            UUID.self,
            name: name,
            serialize: { uuid in
                .string(uuid.uuidString)
            },
            parse: { map in
                guard let string = map.string else {
                    throw GraphQLError(message: "Invalid type for UUID scalar. Expected string, but got \(map.typeDescription)")
                }
                
                guard let uuid = UUID(uuidString: string) else {
                    throw GraphQLError(message: "Invalid uuid string for UUID scalar.")
                }
                
                return uuid
            }
        )
    }
}

public protocol DateFormatter {
    func date(from string: String) -> Date?
    func string(from date: Date) -> String
}

extension Foundation.DateFormatter : DateFormatter {}
@available(OSX 10.12, *)
extension Foundation.ISO8601DateFormatter : DateFormatter {}
