define ['core/workspace'], (Workspace) ->
  createWorkspace: (options) ->
    return new Workspace(options).render()
