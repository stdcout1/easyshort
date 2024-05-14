module Entries exposing (..)

import Browser
import Html exposing (Html, pre, text)


main =
    Browser.element
        { init = init
        , update = update
        , subscriptions = subscriptions
        , view = view
        }


type alias Model =
    { entries : List String
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { entries = [] }, Cmd.none )


type Msg
    = UpdateEntries (List String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateEntries newentries ->
            ( { model | entries = newentries }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    if model.entries == [] then
        text "Empty List"

    else
        text (Debug.toString model.entries)
