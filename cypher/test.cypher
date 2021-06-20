match (n) detach delete n;

drop index text_value if exists;
drop index structure if exists;

call apoc.schema.assert({
}, {
  Locale: ["id", "code"],
  Channel: ["id", "code"],
  Category: ["id", "code"],
  AttributeGroup: ["id", "code"],
  Attribute: ["id", "code"],
  Family: ["id", "code"],
  FamilyVariant: ["id", "code"],
  ProductModel: ["id"],
  Product: ["id", "identifier"]
});

create fulltext index text_value for (v:pim_catalog_text|pim_catalog_textarea|pim_catalog_identifier|pim_catalog_simpleselect|pim_catalog_image|pim_catalog_file|pim_catalog_date) on each [v.value];
create fulltext index structure for ()-[r:TRANSLATED_IN]->() on each [r.translation];

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_locale') yield row
merge (l:Locale {id: row.id}) set l.code = row.code;

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_channel') yield row
merge (c:Channel {id: row.id}) set c.code = row.code;

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_channel_translation') yield row
match (l:Locale {code: row.locale})
match (c:Channel {id: row.foreign_key})
merge (c)-[:TRANSLATED_IN {translation: row.label}]->(l);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_category') yield row
merge (c:Category {id: row.id}) set c.code = row.code
with c, row
match (p:Category {id: row.parent_id})
merge (p)-[:HAS_SUBCATEGORY]->(c);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_category_translation') yield row
match (l:Locale {code: row.locale})
match (c:Category {id: row.foreign_key})
merge (c)-[:TRANSLATED_IN {translation: row.label}]->(l);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_attribute_group') yield row
merge (g:AttributeGroup {id: row.id}) set g.code = row.code;

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_attribute_group_translation') yield row
match (l:Locale {code: row.locale})
match (g:AttributeGroup {id: row.foreign_key})
merge (g)-[:TRANSLATED_IN {translation: row.label}]->(l);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_attribute') yield row
merge (a:Attribute {id: row.id}) set a.code = row.code, a.type = row.attribute_type
with a, row
match (g:AttributeGroup {id: row.group_id})
merge (a)-[:IN_GROUP]->(g);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_attribute_translation') yield row
match (l:Locale {code: row.locale})
match (a:Attribute {id: row.foreign_key})
merge (a)-[:TRANSLATED_IN {translation: row.label}]->(l);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_family') yield row
match (a:Attribute {id: row.label_attribute_id})
merge (f:Family {id: row.id}) set f.code = row.code
merge (a)-[:AS_LABEL]->(f);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_family_translation') yield row
match (l:Locale {code: row.locale})
match (f:Family {id: row.foreign_key})
merge (f)-[:TRANSLATED_IN {translation: row.label}]->(l);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_family_attribute') yield row
match (f:Family {id: row.family_id})
match (a:Attribute {id: row.attribute_id})
merge (f)-[:HAS_ATTRIBUTE]->(a);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_family_variant') yield row
merge (fv:FamilyVariant {id: row.id}) set fv.code = row.code
with fv, row
match (f:Family {id: row.family_id})
merge (f)-[:HAS_VARIANT]->(fv);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_family_variant_translation') yield row
match (l:Locale {code: row.locale})
match (fv:FamilyVariant {id: row.foreign_key})
merge (fv)-[:TRANSLATED_IN {translation: row.label}]->(l);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_family_attribute') yield row
match (f:Family {id: row.family_id})
match (a:Attribute {id: row.attribute_id})
merge (f)-[:HAS_ATTRIBUTE]->(a);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_product_model') yield row
merge (pm:ProductModel {id: row.id}) set pm.code = row.code, pm.identifier = row.identifier, pm.is_enabled = row.is_enabled
with pm, row
match (fv:FamilyVariant {id: row.family_variant_id})
merge (pm)-[:IS_FAMILY_VARIANT]->(fv)
with pm, row
match (pp:ProductModel {id: row.parent_id})
merge (pm)-[:VARIATION_OF]->(pp)

with pm, apoc.convert.fromJsonMap(row.raw_values) as raw_values
unwind keys(raw_values) as code
match (a:Attribute {code: code})
with pm, a, raw_values[a.code] as by_channel
    unwind keys(by_channel) as channel
    with pm, a, channel, by_channel[channel] as by_locale
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
        merge (pm)-[:HAS_VALUE {channel: channel, locale: locale}]->(v)
        with pm, v, a, channel, locale
        call apoc.create.addLabels(v, [a.type]) yield node
        merge (v)-[:FOR_ATTRIBUTE]->(a)
        with v, channel, locale
        match (c:Channel {code: channel})
        merge (v)-[:LOCALIZED]->(c)
        with v, locale
        match (l:Locale {code: locale})
        merge (v)-[:CHANNELED]->(l);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_product') yield row
merge (p:Product {id: row.id}) set p.is_enabled = row.is_enabled, p.identifier = row.identifier
with p, row
optional match (f:Family {id: row.family_id})
merge (p)-[:IS_FAMILY]->(f)
with p, row
optional match (pm:ProductModel {id: row.product_model_id})
merge (p)-[:VARIATION_OF]->(pm)

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
        with v, a, channel, locale
        call apoc.create.addLabels(v, [a.type]) yield node
        merge (v)-[:FOR_ATTRIBUTE]->(a)
        with v, channel, locale
        optional match (c:Channel {code: channel})
        merge (v)-[:CHANNELED]->(c)
        with v, locale
        optional match (l:Locale {code: locale})
        merge (v)-[:LOCALIZED]->(l);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_category_product') yield row
match (c:Category {id: row.category_id})
match (p:Product {id: row.product_id})
merge (c)-[:CATEGORIZE]->(p);

call apoc.load.jdbc('jdbc:mysql://mysql:3306/akeneo_pim?user=root&password=root', 'pim_catalog_category_product_model') yield row
match (c:Category {id: row.category_id})
match (pm:ProductModel {id: row.product_model_id})
merge (c)-[:CATEGORIZE]->(pm);
