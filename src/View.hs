module View
    ( renderGame
    ) where

-- =============================================================== --
-- Interface with Gloss for rendering to output
-- =============================================================== --

import qualified Graphics.Gloss as G
import qualified Model.Types    as T
import qualified Model.Graphics as M
import qualified Model.Geometry as M
import Data.List                     ( sortOn   )

-- =============================================================== --
-- Rendering functions

renderGame :: T.Game -> G.Picture
-- ^Main rendering hub.
renderGame g = renderCube (T.rotation g) . T.cube $ g

---------------------------------------------------------------------
-- Rendering the Rubiks cube

renderCube :: T.Matrix -> T.Cube -> G.Picture
-- ^Given a rotation matrix, convert a Rubiks cube model into a Gloss
-- picture that can be viewed. The Rubiks cube is always pushed back
-- sufficiently far so as to always be fully behind the screen.
renderCube m c =
    let toScreen   = 250                -- Distance from viewer to screen
        cubeCenter = (0,0,100)          -- Vector from screen to cube center
        movement   = M.translatePath cubeCenter -- Push the cube back
                     . M.rotatePath m           -- Rotate cube as viewer wants
    in  G.pictures . snd . unzip        -- render the final cube image
        . reverse . sortOn fst          -- Rendering order of squares by depth
        . map (renderSquare toScreen)   -- Render squares with depth cues
        . M.cubeToSquares movement $ c  -- Position the cube in 3D-space and
                                        -- convert to renderable Squares

---------------------------------------------------------------------
-- Rendering squares
-- Squares are uniform finite planes representing the exposed face
-- each cell in the Rubiks cube. These are used to build up each face
-- of the cube, which are then used to build the cube.

renderSquare :: Float -> T.Square -> (Float, G.Picture)
-- ^Provided a screen distance, convert a renderable square to a
-- Gloss polygon together with a depth cue.
renderSquare d s = ( depth, pic )
    where pic   = colorSquare d s . G.polygon $ ps
          ps    = [ (x, y) | (x,y,_) <- T.points . M.project d $ s ]
          depth = minimum [ z | (_,_,z) <- T.points s ]

colorSquare :: Float -> T.Square -> G.Picture -> G.Picture
-- Color the square depending on whether it is facing towards or away
-- from the viewer.
colorSquare d s
    | M.isFacingViewer d s = G.color (renderColor . T.front $ s)
    | otherwise            = G.color (renderColor . T.back  $ s)

---------------------------------------------------------------------
-- Gloss-Model interface functions

renderColor :: T.Color -> G.Color
-- ^Map Model colors to Gloss colors.
renderColor T.Red    = G.makeColor 0.78 0.15 0.10 1.0
renderColor T.White  = G.makeColor 0.75 0.75 0.75 1.0
renderColor T.Yellow = G.makeColor 1.00 0.85 0.34 1.0
renderColor T.Green  = G.makeColor 0.00 0.54 0.36 1.0
renderColor T.Blue   = G.makeColor 0.00 0.64 1.00 1.0
renderColor T.Orange = G.makeColor 1.00 0.38 0.00 1.0
renderColor T.Hidden = G.makeColor 0.10 0.10 0.10 1.0
