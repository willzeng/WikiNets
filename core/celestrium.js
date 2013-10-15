define(['core/workspace'], function(Workspace) {

  return {
    createWorkspace: function(options) {
      return new Workspace(options).render();
    },

  };

});