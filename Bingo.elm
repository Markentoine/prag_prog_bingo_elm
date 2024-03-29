module Bingo exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder, field, succeed)
import Json.Encode as Encode exposing (..)
import Random



-- UPDATE


type Msg
    = NewGame
    | Mark Int
    | SortByPoint
    | NewRandom Int
    | NewEntries (Result Http.Error (List Entry))
    | CloseAlert
    | ShareScore
    | NewScore (Result Http.Error Score)
    | SetNameInput String
    | SaveName
    | CancelName
    | ChangeGameState GameState


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ChangeGameState state ->
            ( { model | gameState = state }, Cmd.none )

        SaveName ->
            ( { model | name = model.nameInput, nameInput = "", gameState = Playing }, Cmd.none )

        CancelName ->
            ( { model | nameInput = "", gameState = Playing }, Cmd.none )

        CloseAlert ->
            ( { model | alertMessage = Nothing }, Cmd.none )

        NewGame ->
            ( { model
                | gameNumber = model.gameNumber + 1
                , gameState = EnteringName
              }
            , getEntries
            )

        NewEntries (Ok randomEntries) ->
            ( { model | entries = randomEntries }, Cmd.none )

        NewEntries (Err error) ->
            let
                errorMessage =
                    case error of
                        Http.NetworkError ->
                            "Le serveur fonctionne?"

                        _ ->
                            "PROBLEME!"
            in
            ( { model | alertMessage = Just errorMessage }, Cmd.none )

        NewScore (Ok score) ->
            let
                message =
                    "Your score of "
                        ++ toString score.score
                        ++ "has been successfully shared!"
            in
            ( { model | alertMessage = Just message }, Cmd.none )

        NewScore (Err error) ->
            let
                message =
                    "Unable to share your score: "
                        ++ toString error
            in
            ( { model | alertMessage = Just message }, Cmd.none )

        Mark id ->
            let
                markEntry e =
                    if e.id == id then
                        { e | marked = not e.marked }

                    else
                        e
            in
            ( { model | entries = List.map markEntry model.entries }, Cmd.none )

        SetNameInput input_value ->
            ( { model | nameInput = input_value }, Cmd.none )

        ShareScore ->
            ( model, postScore model )

        SortByPoint ->
            ( { model | entries = List.sortBy .points model.entries }, Cmd.none )

        NewRandom randomNum ->
            ( { model | gameNumber = randomNum }, Cmd.none )



-- DECODERS / ENCODERS


entryDecoder : Decoder Entry
entryDecoder =
    Decode.map4 Entry
        (field "id" Decode.int)
        (field "phrase" Decode.string)
        (field "points" Decode.int)
        (succeed False)


scoreDecoder : Decoder Score
scoreDecoder =
    Decode.map3 Score
        (field "id" Decode.int)
        (field "name" Decode.string)
        (field "score" Decode.int)


encodeScore : Model -> Encode.Value
encodeScore model =
    Encode.object
        [ ( "name"
          , Encode.string model.name
          )
        , ( "score"
          , Encode.int (sumMarkedPoints model.entries)
          )
        ]



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


postScore : Model -> Cmd Msg
postScore model =
    let
        url =
            "http://localhost:3000/scores"

        body =
            encodeScore model
                |> Http.jsonBody

        request =
            Http.post url body scoreDecoder
    in
    Http.send NewScore request



-- MODEL


type GameState
    = EnteringName
    | Playing


type alias Model =
    { name : String
    , gameNumber : Int
    , entries : List Entry
    , alertMessage : Maybe String
    , nameInput : String
    , gameState : GameState
    }


type alias Entry =
    { id : Int
    , phrase : String
    , points : Int
    , marked : Bool
    }


type alias Score =
    { id : Int
    , name : String
    , score : Int
    }


initialModel : Model
initialModel =
    { name = "Anonymous"
    , gameNumber = 1
    , entries = []
    , alertMessage = Nothing
    , nameInput = ""
    , gameState = EnteringName
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
        [ a [ href "#", onClick (ChangeGameState EnteringName) ] [ text (String.toUpper name) ]
        , text (("- GAME #" ++ toString gameNumber) |> String.toUpper)
        ]


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


viewNameInput : Model -> Html Msg
viewNameInput model =
    case model.gameState of
        EnteringName ->
            div [ class "name-input" ]
                [ input
                    [ type_ "text"
                    , placeholder "Who's playing?"
                    , autofocus True
                    , value model.nameInput
                    , onInput SetNameInput
                    ]
                    []
                , button [ onClick SaveName ] [ text "Save" ]
                , button [ onClick CancelName ] [ text "Cancel" ]
                ]

        Playing ->
            text ""


viewAlertMessage : Maybe String -> Html Msg
viewAlertMessage alertMessage =
    case alertMessage of
        Just message ->
            div [ class "alert" ]
                [ span [ class "close", onClick CloseAlert ] [ text "X" ]
                , text message
                ]

        Nothing ->
            text ""


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
        , viewAlertMessage model.alertMessage
        , viewNameInput model
        , viewEntryList model.entries
        , viewScore (sumMarkedPoints model.entries)
        , div [ class "button-group" ]
            [ button [ onClick NewGame ] [ text "New Game" ]
            , button [ onClick ShareScore ] [ text "Share Score" ]
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
