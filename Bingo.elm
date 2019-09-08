module Bingo exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)


playerInfo : String -> Int -> String
playerInfo name gameNumber =
    name ++ " - Game #" ++ toString gameNumber



-- MODEL


initalModel =
    { name = "Jerome"
    , gameNumber = 1
    , entries = intialEntries
    }


initialEntries =
    [ { id = 1, phrase = "Future-proof", points = 100, marked = False }
    , { id = 1, phrase = "Doing Agile", points = 200, marked = False }
    ]



-- VIEW


viewHeader : String -> Html msg
viewHeader title =
    header []
        [ h1 [] [ text title ] ]


viewPlayer : String -> Int -> Html msg
viewPlayer name gameNumber =
    let
        playerInfoText =
            playerInfo name gameNumber
                |> String.toUpper
                |> Html.text
    in
    h2 [ id "info", class "classy" ]
        [ playerInfoText ]


viewFooter : Html msg
viewFooter =
    footer []
        [ a [ href "http://elm-lang.org" ]
            [ text "powered by Elm" ]
        ]


view : Html msg
view =
    div [ class "content" ]
        [ viewHeader "BUZZWORD BINGO"
        , viewPlayer "jerome" 9
        , viewFooter
        ]


main : Html msg
main =
    view
