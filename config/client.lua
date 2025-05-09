return {
  loadingModelsTimeout = 10000, -- Waiting time for ox_lib to load the models before throws an error, for low specs pc
  defaultAllowedCharacters = 4, -- The amount of characters you can have in total

  characters = {
    locations = { -- Spawn locations for multichar, these are chosen randomly
      {
        pedCoords = vec4(969.25, 72.61, 116.18, 276.55),
        camCoords = vec4(972.2, 72.9, 116.68, 97.27),
      }
    },
  },

  ui = {
    title = "FIVEM ROLEPLAY", -- The main title shown at the top
    subtitle = "SELECT CHARACTER", -- The subtitle shown below the main title
    defaultFivemName = "FiveM Name", -- Default text shown when FiveM name is not available
    height = {
      default = 170, -- Default height in cm
      min = 110, -- Minimum height in cm
      max = 220, -- Maximum height in cm
    }
  }
}
