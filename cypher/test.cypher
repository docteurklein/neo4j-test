match (n) detach delete n;

drop index text_value if exists;

call apoc.schema.assert({
}, {
  AttributeGroup: ["id", "code"],
  Attribute: ["id", "code"],
  Family: ["id", "code"],
  Product: ["id", "identifier"]
});

create fulltext index text_value for (v:pim_catalog_text|pim_catalog_textarea|pim_catalog_identifier|pim_catalog_simpleselect|pim_catalog_image|pim_catalog_file|pim_catalog_date) on each [v.value];

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_attribute_group') yield row
merge (g:AttributeGroup {id: row.id}) set g.code = row.code;

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_attribute') yield row
merge (a:Attribute {id: row.id}) set a.code = row.code, a.type = row.attribute_type
with a, row
match (g:AttributeGroup {id: row.group_id})
merge (a)-[:IN_GROUP]->(g);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_family') yield row
match (a:Attribute {id: row.label_attribute_id})
merge (f:Family {id: row.id}) set f.code = row.code
merge (f)-[:AS_LABEL]->(a);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_family_attribute') yield row
match (f:Family {id: row.family_id}),
      (a:Attribute {id: row.attribute_id})
merge (f)-[:HAS_ATTRIBUTE]->(a);


call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_product') yield row
match (f:Family {id: row.family_id})
merge (p:Product {id: row.id}) set p.is_enabled = row.is_enabled, p.identifier = row.identifier
merge (p)-[:IS_FAMILY]->(f)

with p, apoc.convert.fromJsonMap(row.raw_values) as raw_values
unwind keys(raw_values) as code
match (a:Attribute {code: code})
with p, a, raw_values[a.code] as by_channel
    unwind keys(by_channel) as channel
    with p, a, channel, by_channel[channel] as by_locale
        unwind keys(by_locale) as locale
        merge (v:Value {
            value: case a.type
                    when 'pim_catalog_text' then by_locale[locale]
                    when 'pim_catalog_textarea' then by_locale[locale]
                    when 'pim_catalog_identifier' then by_locale[locale]
                    when 'pim_catalog_number' then by_locale[locale]
                    when 'pim_catalog_date' then by_locale[locale]
                    when 'pim_catalog_boolean' then by_locale[locale]
                    when 'pim_catalog_simpleselect' then by_locale[locale]
                    when 'pim_catalog_image' then by_locale[locale]
                    when 'pim_catalog_file' then by_locale[locale]
                    //when 'pim_catalog_price_collection' then by_locale[locale]
                    //when 'pim_catalog_metric' then by_locale[locale]
                    //when 'pim_catalog_multiselect' then by_locale[locale]
                    else apoc.convert.toJson(by_locale[locale])
                end
            })
        merge (p)-[:HAS_VALUE {channel: channel, locale: locale}]->(v)
        with v, a
        call apoc.create.addLabels(v, [a.type]) yield node
        merge (v)-[:FOR_ATTRIBUTE]->(a);
