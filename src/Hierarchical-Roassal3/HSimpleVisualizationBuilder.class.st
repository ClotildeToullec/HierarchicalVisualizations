"
A basic visualization based on the video presented by nicolas
"
Class {
	#name : #HSimpleVisualizationBuilder,
	#superclass : #RSAbstractContainerBuilder,
	#instVars : [
		'rootNode',
		'colors'
	],
	#category : #'Hierarchical-Roassal3'
}

{ #category : #hooks }
HSimpleVisualizationBuilder >> borderFor: node [
	^ node hasChildren
		ifTrue: [ RSBorder new 
			width: 2; 
			capSquare;
			joinMiter;
			color: Smalltalk ui theme textColor;
			dashArray: #(5 10);
			yourself  ]
		ifFalse: [ nil ]
]

{ #category : #hooks }
HSimpleVisualizationBuilder >> childrenFor: node [
	^ node children collect: [ :child | self shapeFor: child ]
]

{ #category : #hooks }
HSimpleVisualizationBuilder >> colorFor: node [
	^ colors scale: node
]

{ #category : #initialization }
HSimpleVisualizationBuilder >> initialize [
	super initialize.
	colors := NSScale category20c.
]

{ #category : #hooks }
HSimpleVisualizationBuilder >> menuInteraction [
	^ RSMenuActivable new
		menuDo: [ :menu :box | 
			menu 
				add: 'Expand/Collapse'
				target: box model
				selector: #expandCollapse
				argument: #();
				
				add: 'Inspect'
				target: box model
				selector: #inspect
				argument: #() ];
		yourself.
]

{ #category : #hooks }
HSimpleVisualizationBuilder >> rebuild: node shape: shape [
	| canvas newShape |
	canvas := shape canvas.
	canvas lines copy do: #remove.
	shapes removeAll: (shape withAllChildren select: [:s | s class = RSComposite]).
	newShape := self shapeFor: node.
	newShape position: shape position.
	shape parent add: newShape.
	shape remove.

	self renderLinesIn: canvas.
	canvas signalUpdate.
		
]

{ #category : #hooks }
HSimpleVisualizationBuilder >> renderIn: aCanvas [
	| rootShapes |
	aCanvas color: Smalltalk ui theme backgroundColor.
	shapes := RSGroup new.
	rootShapes := rootNode children collect: [:child | self shapeFor: child ].
	aCanvas addAll: rootShapes.

	self renderLinesIn: aCanvas.
	RSGridLayout new
		gapSize: 50;
		on: rootShapes.
	aCanvas @ (RSCanvasController new 
		in: [:i | 
			aCanvas newAnimation
				duration: 500 milliSeconds;
				onStepDo: [ aCanvas signalUpdate ];
				when: RSAnimationEndEvent do: [ i configuration noZoomToFitOnExtendChanged  ].
			i configuration useBasicZoom ];
		yourself).
]

{ #category : #hooks }
HSimpleVisualizationBuilder >> renderLinesIn: aCanvas [

	RSLineBuilder line "bezier"
		"controlPointsController: HVisualizationCPController new;"
		"markerStartEnd: (RSEllipse new size: 3);"
		attachPoint: (RSBorderAttachPoint new endOffset: 5);
		markerEnd: (RSShapeFactory arrow size: 10);
		color: Smalltalk ui theme textColor;
		canvas: aCanvas;
		shapes: shapes;
		connectFromAll: #dependentsFromLinks.
]

{ #category : #accessing }
HSimpleVisualizationBuilder >> rootNode [
	^ rootNode
]

{ #category : #accessing }
HSimpleVisualizationBuilder >> rootNode: aHNode [ 
	rootNode := aHNode
]

{ #category : #hooks }
HSimpleVisualizationBuilder >> shapeFor: node [
	^ RSComposite new
		model: node;
		color: (self colorFor: node);
		popup;
		draggable;
		addInteraction: self menuInteraction;
		addInteraction: RSLabeled;
		addInteraction: RSHighlightable red withLines;
		size: 50;
		in: [ :shape | 
			node isExpanded ifTrue: [ | childrenShapes |
				shape addAll: (childrenShapes := self childrenFor: node).
				RSGridLayout new gapSize: 30; on: childrenShapes.
				shape
					withBorder;
					adjustToChildren;
					padding: 10.
			] ifFalse: [ shape border: (self borderFor: node) ].
			node 
				removeInteractionIfPresent: self class;
				when: HCollapseEvent do: [ :evt | self rebuild: evt node shape: shape ];
				when: HExpandEvent do: [ :evt | self rebuild: evt node shape: shape ].
			shapes add: shape ];
		yourself.
	
]