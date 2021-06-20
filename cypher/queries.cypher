
// find product that has something looking like "Lautstärkeregler" in its de_DE description attribute
CALL db.index.fulltext.queryNodes("text_value", "Lautstärkeregler~") YIELD node, score
MATCH (node)-[:FOR_ATTRIBUTE]->(a:Attribute {code: 'description'}),
      (p:Product)-[:HAS_VALUE {locale: "de_DE"}]->(node)
RETURN node.value, score;

// find all product values (including those inherited from product models)
MATCH n=(p:Product {identifier: "1111111131"})-[:HAS_VALUE]->() RETURN n LIMIT 25;

// find *all* product values localized in french
MATCH p=()-[r:HAS_VALUE {locale: 'fr_FR'}]->() RETURN p LIMIT 25;


////////////////////// trigger examples for later

// // when we add the surname property on a node, it’s added to all the nodes connected (in this case one level deep)
//  CALL apoc.trigger.add('setAllConnectedNodes','UNWIND apoc.trigger.propertiesByKey($assignedNodeProperties,"surname") as prop
// WITH prop.node as n
// MATCH(n)-[]-(a)
// SET a.surname = n.surname', {phase:'after'});
// 
// // when the label Actor of a node is removed, update all labels Actor with Person
// CALL apoc.trigger.add('updateLabels',"UNWIND apoc.trigger.nodesByLabel($removedLabels,'Actor') AS node
// MATCH (n:Actor)
// REMOVE n:Actor SET n:Person SET node:Person", {phase:'before'})
// 
// 
// // when the label Actor of a node is removed, update all labels Actor with Person
// CALL apoc.trigger.add('updateLabels',"UNWIND apoc.trigger.nodesByLabel($removedLabels,'Actor') AS node
// MATCH (n:Actor)
// REMOVE n:Actor SET n:Person SET node:Person", {phase:'before'})
// 
// // connect every new node with label Actor and as name property a specific values
// CALL apoc.trigger.add('create-rel-new-node',"UNWIND $createdNodes AS n
// MATCH (m:Movie {title:'Matrix'})
// WHERE n:Actor AND n.name IN ['Keanu Reeves','Laurence Fishburne','Carrie-Anne Moss']
// CREATE (n)-[:ACT_IN]->(m)", {phase:'before'})
// 
// 
// // validate property
// CALL apoc.trigger.add("forceStringType",
// "UNWIND apoc.trigger.propertiesByKey($assignedNodeProperties, 'reference') AS prop
// CALL apoc.util.validate(apoc.meta.type(prop) <> 'STRING', 'expected string property type, got %s', [apoc.meta.type(prop)]) RETURN null", {phase:'before'})
// 
// CALL apoc.trigger.add('timestamp','UNWIND $createdNodes AS n SET n.ts = timestamp()');
// CALL apoc.trigger.add('lowercase','UNWIND $createdNodes AS n SET n.id = toLower(n.name)');
// CALL apoc.trigger.add('txInfo',   'UNWIND $createdNodes AS n SET n.txId = $transactionId, n.txTime = $commitTime', {phase:'after'});
// CALL apoc.trigger.add('count-removed-rels','MATCH (c:Counter) SET c.count = c.count + size([r IN $deletedRelationships WHERE type(r) = "X"])')
// CALL apoc.trigger.add('lowercase-by-label','UNWIND apoc.trigger.nodesByLabel($assignedLabels,'Person') AS n SET n.id = toLower(n.name)')

// // add rel for each assigned rel prop
// CALL apoc.trigger.add('test-rel-trigger',
// UNWIND keys({assignedRelationshipProperties}) AS key
// UNWIND {assignedRelationshipProperties}[key] AS map
// WITH map WHERE type(map.relationship) = "HAS_VALUE_ON"
// CALL apoc.index.addRelationship(map.relationship, keys(map.relationship)) RETURN count(*)'
// , {phase:'before'})
