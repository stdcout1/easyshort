module Redirect exposing (Model, Msg(..), init, main, subscriptions, update, view)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Http
import Url exposing (Protocol(..))



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        }



-- MODEL


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , redirection : Redirection
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( Model key url Waiting, getLink (url.path |> String.dropLeft 1) )


getLink : String -> Cmd Msg
getLink url =
    Http.request
        { method = "POST"
        , headers = []
        , url = "https://backend.sh.nasirk.ca/get_link"
        , body = Http.stringBody "text/plain" (Debug.log "url: " url)
        , expect = Http.expectString Recived
        , timeout = Just 5000
        , tracker = Nothing
        }



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | Recived (Result Http.Error String)


type Redirection
    = Waiting
    | Destination String
    | Error Http.Error


redirectionString : Redirection -> String
redirectionString r =
    case r of
        Waiting ->
            "..."

        Destination string ->
            string

        Error e ->
            Debug.toString e


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.key (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        Recived res ->
            case res of
                Ok string ->
                    ( { model | redirection = Destination string }, Nav.load string )

                Err err ->
                    ( { model | redirection = Error err }, Cmd.none )

        UrlChanged url ->
            ( { model | url = url }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "sh"
    , body =
        [ h1 [ style "text-align" "center" ]
            [ text ("Redirecting: " ++ model.url.path ++ " --> " ++ redirectionString model.redirection)
            ]
        ]
    }
