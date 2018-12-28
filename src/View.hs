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
-- ^Main rendering function.
renderGame g = G.pictures [ renderCube g
                          , renderButtons g
                          ]

---------------------------------------------------------------------
-- Rendering the Rubiks cube

renderButtons :: T.Game -> G.Picture
-- ^Render the control buttons for exiting, reseting, undoing, etc.
renderButtons g = G.translate dx dy . G.bitmapOfBMP . T.btnSheet $ g
    where (w,h) = T.dim g
          dy    = fromIntegral h / 2 - 20
          dx    = -1 * ( fromIntegral w / 2 - 80 )

renderCube :: T.Game -> G.Picture
-- ^Given a rotation matrix, convert a Rubiks cube model into a Gloss
-- picture that can be viewed. The Rubiks cube is always pushed back
-- sufficiently far so as to always be fully behind the screen.
renderCube g = G.pictures . snd . unzip     -- Render the final cube image
               . reverse . sortOn fst       -- Rendering order of squares
               . map (renderSquare g)       -- is based on the depth cues.
               . M.cubeToSquares (M.positionCube g)
               $ T.cube g

---------------------------------------------------------------------
-- Rendering squares
-- Squares are uniform finite planes representing the exposed face
-- each cell in the Rubiks cube. These are used to build up each face
-- of the cube, which are then used to build the cube.

renderSquare :: T.Game -> T.Square -> (Float, G.Picture)
-- ^Provided a screen distance, convert a renderable square to a
-- Gloss polygon together with a depth cue. Antialiasing is mimiced
-- by applying a semi-transparent border.
renderSquare g s = ( depth, fill <> brdr )
    where clr  = squareColor g s
          fill = G.color clr . G.polygon $ ps
          brdr = G.color (G.withAlpha 0.5 clr) . G.lineLoop $ ps
          ps   = [ (x,y) | (x,y,_) <- T.points . M.project (T.toScreen g) $ s ]
          depth = minimum [ z | (_,_,z) <- T.points s ]

squareColor :: T.Game -> T.Square -> G.Color
-- Determine the Gloss color of the square depending on whether it is
-- facing towards or away from the viewer and selected or not.
squareColor g s
    | not . M.isFacingViewer d $ s = renderColor . T.back $ s
    | isSelected                   = G.bright . renderColor . T.front $ s
    | otherwise                    = renderColor. T.front $ s
    where d = T.toScreen g
          isSelected = case T.mode g of
                            T.Selected lc -> lc == T.locus s
                            otherwise     -> False

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
