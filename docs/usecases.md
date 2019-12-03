# Knowledge Graph Use Cases

We see the primary challenges of knowledge graph development revolving around **knowledge curation**, **knowledge interaction**, and **knowledge inference**.
We will enumerate a number of capabilities expressed as user stories of the form:

> As *who/role*, I want/want to/need/can/would like *what/goal*, so that *why/benefit*.

We also note how Whyis currently implements that user story. This is an evolving set of stories, but is a guide to the kinds of tasks we see as core tasks in Whyis.

## Knowledge Curation
These stories are about acquiring knowledge from external sources and users.

### Semantic Extract, Transform, and Load (SETL)

>As a knowledge curator, I can reproducibly transform data into a common knowledge representation so that knowledge can be automatically incorporated from external sources.

Semantic ETL is realized using the [Semantic Extract, Transform, and Load-r (SETLr)](https://github.com/tetherless-world/setlr) to support conversion of tabular data, JSON, XML, HTML, and other custom formats (through embedded python) into RDF suitable for the knowledge graph, as well as transforming existing RDF into a better desired representation.
By loading SETL scripts (written in RDF) into the knowledge graph, the SETLr inference agent is triggered, which runs the script and imports the generated RDF.
SETLr itself is powerful enough to support the creation of named graphs, which lets users control not just nanopublication assertions (as would be the case if they were simply generating triples), but also provenance and publication info.
SETLr in Whyis also supports the parameterization of SETL scripts by file type.
Users can upload files to nodes by HTTP POSTing a file to a node's URI.
The node then represents that file.
When adding new metadata about that node, it can include *rdf:type*.
If a file node has a type that matches one that is used in a SETL script, the file is converted using that script into RDF.
This lets users (and developers) upload domain-specific file types to contribute knowledge.
We have provided an example that supports the [conversion of BibTeX files into publication metadata](https://raw.githubusercontent.com/tetherless-world/whyis/master/setl_scripts/bibtex.setl.ttl) that is compatible with Digital Object Identifier (DOI) Linked Data.

### Revision

>  As a knowledge curator, I can identify and replace knowledge with new revisions so that the current state of the knowledge graph can be queried in a consistent way.
  
  Revisions are expressed by creating a new nanopublication and marking it as a *prov:wasRevisionOf* the original. 
The revision and anything that *prov:wasDerivedFrom* the prior version are "retired", or removed from the RDF database. 
Retired nanopublications are still accessible as linked data from a file archive that stores all nanopublications ever published in the knowledge graph. 
It is therefore possible to query on current knowledge, but trace back to historical knowledge.
The use of *prov:wasDerivedFrom* is essential to truth maintenance, in that agents (and other users of the knowledge graph) are expected to enumerate the nanopublications they use to produce additional knowledge.
Whyis is fundamentally organized around the nanopublication as an atom of knowledge and provenance as the means of tracking and organizing that knowledge. 
Every statement in the knowledge graph is part of a nanopublication, and meta-knowledge, like the probability of a knowledge statement, is expressed as a nanopublication that talks about other nanopublications.

### On Demand Load

>  As a knowledge curator, I can map to external data sources that can be loaded on-demand, including linked data and raw files.

Whyis provides a flexible Linked Data importer that can load RDF from remote Linked Data sources by URL prefix.
We have successfully tested use of this importer with [DOI](http://dx.doi.org), [OBO Foundry Ontologies](http://obofoundry.org), [Uniprot](http://uniprot.org), [DBPedia](http://dbpedia.org), and other project-specific resources.
It supports the insertion of API keys, content negotiation, and HTTP authentication using a netrc file.
It tracks the last modified time of remote RDF to only update when remote data has changed and provides provenance indicating that the imported RDF *prov:wasQuotedFrom* the original URL.
[Examples are available](https://raw.githubusercontent.com/tetherless-world/whyis/master/config_defaults.py) in the default configuration file in the *importers* entry.
Whyis also provides a file importer that, rather than parsing the remote file as RDF, loads the file into the file depot.
This can be invoked on-demand, so that metadata can be loaded from one SETL script about a collection of files, then other SETL scripts can process those files based on the types added, and the files would be dynamically downloaded to Whyis for processing.

### Commentary

> As a user exploring the knowledge graph, I can comment on nodes and fragments of knowledge to add plain text notes to the graph, so that my feedback can be used to improve the graph.

Users can provide commentary on nodes and nanopublications through the default view. 
This view can be re-used and customized by developers. 
Nanopublications can be replied to, which themselves become nanopublications.
The text of the commentary is interpreted as [semantic markdown](https://github.com/tetherless-world/markdown-rdfa) in order to extract potential RDF from the commentary.
This comment-like system realizes the use case in [Kuhn *et al.*](https://dx.doi.org/10.1007/978-3-642-38288-8_33) of providing natural language nanopublications.

## Knowledge Interaction
These stories are about accessing and displaying knowledge to human and computational users.

### Custom Views

> As a knowledge graph developer, I can create custom web or data (API) views for my users so that they can see the most relevant information about a node of interest.

Developers of Whyis knowledge graphs can create custom views for nodes by both the *rdf:type* of the node and the `view` URL parameter. 
These views are looked up as templates and rendered using the [Jinja2 templating engine](http://jinja.pocoo.org/docs/2.10).
This is configured in a "vocab" turtle file, where viewed classes and view properties are defined.
For instance, to define a default view on the class *sio:Protein*, see below. 
For all nodes that are of type *sio:Protein*, when a user visits the node page, the `protein_view.html` template will be rendered.

```turtle
sio:Protein whyis:hasView "protein_view.html".
```

If different views for a type are desired, developers can define those custom views. For instance, if the code below is added to the vocabulary, when the page for a given protein is given the parameter `view=structure`, the `protein_structure_view.html` template will be used.
Other templates can be used for the same view, if the same predicate is used to link types to the desired template.
In BioKG, this capability is used to provide biology-specific incoming and outgoing link results.
For more details, please see the [view documentation](http://tetherless-world.github.io/whyis/views).

```turtle
ex:structureView rdfs:subPropertyOf whyis:hasView;
    dcterms:identifier "structure".
sio:Protein ex:structureView "protein_structure_view.html".
```

### Explanation
  
> As a knowledge graph developer, I can query for the source of a displayed fragment of knowledge so that the UI can provide justification for it to the user.

Through the use of nanopublications, developers can provide explanation for all assertions
made in the graph by accessing the linked provenance graph when a user asks for more details.

### Search
  
> As a user I can search for graph nodes based on their label or the text descriptions associated with them so that I can find nodes of interest.

Search is supported, and provides an entity resolution-based autocomplete and a full text search page.

## Knowledge Inference
These stories are about expanding the knowledge graph based on knowledge already included in the graph.

Knowledge Inference in Whyis is performed by a suite of *Agents*, each performing the analogue to a single rule in traditional deductive inference. 

### Custom Inference

> As a knowledge graph developer, I can write custom algorithms that listen for changes of interest in the graph and produce arbitrary knowledge output based on those changes.
  
The agent framework provides custom inference capability, and is composed of a SPARQL query that serves as the *rule body* and a python function that serves has the *head*.
The agent is invoked when new nanopublications are added to the knowledge graph that match the SPARQL query defined by the agent.
Developers can choose to run this query either on just the single nanopublication that has been added, or on the entire graph.
Whole-graph queries will need to exclude query matches that would cause the agent to be invoked over and over.
This can take some consideration for complex cases, but excluding similar knowledge to the expected output or nodes that have already had the agent run on them will often suffice.
The function *head* is invoked on each query match.
This function can produce unqualified RDF or full nanopublications.
The agent superclass will assign some basic provenance and publication information related to the given inference activity, but developers can expand on this by overriding the *explain()* function. 

### Custom Rules
 
> As a knowledge graph developer, I can add custom deductive rules so that I can expand the knowledge graph using domain-specific rule expansion knowledge.

Whyis provides support for custom deductive rules using the autonomic.Deductor class.
Developers can write rules by providing a _construct_ clause as the head and a _where_ clause as the body.

### Standard Inferencing
 
> As a knowledge graph developer, I can add deductive inferencing support for standard entailment regimes, like RDFS, OWL 2 profiles (DL, RL, QL, and EL) so that I can query over the deductive closure of the graph as well as the explicit inferences.
 
Whyis provides customized Deductor instances that are collected up into OWL 2 partial profiles (with an eye towards near-term completion of them) for OWL 2 EL, RL, and QL.

### NLP Support

> As a knowledge graph developer, I can add NLP algorithms that read text changes in the graph and produce structured knowledge extracted from that text.

Default inference agent types include some NLP support, including entity detection using noun phrase extraction, basic entity resolution against other knowledge graph nodes, and Inverse Document Frequency computation for resolved nodes.

### Truth Maintenance

> As a knowledge graph system, I apply generalized truth maintenance to all inferred knowledge, regardless of source, so that revisions to the graph maintain consistency with itself.
 
Truth maintenance is performed through derivation tracing. When a nanopublication is retired from the knowledge graph, either through revision or retirement, all nanopublications that are transitively derived from (*prov:wasDerivedFrom*) the original nanopublication are also retired.
When a revision occurs, the inclusion of a new nanopublication triggers inference agents to be run on its content, creating a re-calculation cascade in the case of revisions.
