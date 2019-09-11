module Bingo exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick)
import Http
import Json.Decode as Decode exposing (Decoder, field, succeed)
import Random



-- UPDATE


type Msg
    = NewGame
    | Mark Int
    | SortByPoint
    | NewRandom Int
    | NewEntries (Result Http.Error (List Entry))
    | Alert


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Alert -> 

        NewGame ->
            ( { model
                | gameNumber = model.gameNumber + 1
              }
            , getEntries
            )

        NewEntries (Ok randomEntries) ->
            ( { model | entries = randomEntries }, Cmd.none )

        NewEntries (Err error) ->
            let
                errorMessage =
                    "Server Down"
            in
            ( model, Cmd.none )

        Mark id ->
            let
                markEntry e =
                    if e.id == id then
                        { e | marked = not e.marked }

                    else
                        e
            in
            ( { model | entries = List.map markEntry model.entries }, Cmd.none )

        SortByPoint ->
            ( { model | entries = List.sortBy .points model.entries }, Cmd.none )

        NewRandom randomNum ->
            ( { model | gameNumber = randomNum }, Cmd.none )



-- DECODERS


entryDecoder : Decoder Entry
entryDecoder =
    Decode.map4 Entry
        (field "id" Decode.int)
        (field "phrase" Decode.string)
        (field "points" Decode.int)
        (succeed False)



-- COMMANDS


generateRandomNumber : Cmd Msg
generateRandomNumber =
    Random.generate (\num -> NewRandom num) (Random.int 1 100)


entriesUrl : String
entriesUrl =
    "http://localhost:3000/random-entries"


getEntries : Cmd Msg
getEntries =
    Decode.list entryDecoder
        |> Http.get entriesUrl
        |> Http.send NewEntries



-- MODEL


type alias Model =
    { name : String
    , gameNumber : Int
    , entries : List Entry
    , alertMessage : Maybe String
    }


type alias Entry =
    { id : Int
    , phrase : String
    , points : Int
    , marked : Bool
    }


initialModel : { name : String, gameNumber : Int, entries : List Entry, alertMessage : Maybe String }
initialModel =
    { name = "Jerome"
    , gameNumber = 1
    , entries = []
    , alertMessage = Nothing
    }



-- VIEW


playerInfo : String -> Int -> String
playerInfo name gameNumber =
    name ++ " - Game #" ++ toString gameNumber


viewHeader : String -> Html Msg
viewHeader title =
    header []
        [ h1 [] [ text title ] ]


viewPlayer : String -> Int -> Html Msg
viewPlayer name gameNumber =
    let
        playerInfoText =
            playerInfo name gameNumber
                |> String.toUpper
                |> Html.text
    in
    h2 [ id "info", class "classy" ]
        [ playerInfoText ]


viewEntryItem : Entry -> Html Msg
viewEntryItem entry =
    li [ classList [ ( "marked", entry.marked ) ], onClick (Mark entry.id) ]
        [ span [ class "phrase" ] [ text entry.phrase ]
        , span [ class "points" ] [ text (toString entry.points) ]
        ]


viewEntryList : List Entry -> Html Msg
viewEntryList entries =
    entries
        |> List.map viewEntryItem
        |> ul []


sumMarkedPoints : List Entry -> Int
sumMarkedPoints entries =
    entries
        |> List.filter .marked
        |> List.map .points
        |> List.foldl (+) 0


viewScore : Int -> Html Msg
viewScore sum =
    div [ class "score" ]
        [ span [ class "label" ] [ text "Score" ]
        , span [ class "value" ] [ text (toString sum) ]
        ]


viewAllEntriesMarked : List Entry -> Html Msg
viewAllEntriesMarked entries =
    let
        allEntriesMarked =
            List.all .marked entries
    in
    div [] [ text ("All entries marked: " ++ toString allEntriesMarked) ]


viewFooter : Html Msg
viewFooter =
    footer []
        [ a [ href "http://elm-lang.org" ]
            [ text "powered by Elm" ]
        ]


view : Model -> Html Msg
view model =
    div [ class "content" ]
        [ viewHeader "BUZZWORD BINGO"
        , viewPlayer model.name model.gameNumber
        , viewEntryList model.entries
        , viewScore (sumMarkedPoints model.entries)
        , div [ class "button-group" ]
            [ button [ onClick NewGame ] [ text "New Game" ]
            , button [ onClick SortByPoint ] [ text "Sort by Points" ]
            ]
        , viewAllEntriesMarked model.entries
        , viewFooter
        ]


main : Program Never Model Msg
main =
    Html.program
        { init = ( initialModel, getEntries )
        , view = view
        , update = update
        , subscriptions = \_ -> Sub.none
        }
