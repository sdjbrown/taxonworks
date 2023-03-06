const DEFAULT_NODE_STYLE = {
  color: '#3355bb',
  hoverColor: '#3355bb'
}

export const unsavedEdge = {
  color: '#9ca5a7',
  dasharray: 5,
  hoverColor: '#dedede',
  hoverDasharray: 5
}

export const unsavedNodeStyle = {
  strokeDasharray: 5,
  strokeWidth: 2,
  strokeColor: '#9ca5a7',
  color: '#dfdfdf',
  hoverColor: '#dedede'
}

export const nodeCollectionObjectStyle = {
  type: 'rect',
  ...DEFAULT_NODE_STYLE
}

export const nodeOtuStyle = {
  type: 'circle',
  ...DEFAULT_NODE_STYLE
}
