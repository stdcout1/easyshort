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
        , url = "http://172.245.42.218:3000/get_link"
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
    | Error Http.Error


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
                    ( model, Nav.load string )

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
    { title = "URL Interceptor"
    , body =
        [ text "Redirecting"
        , text model.url.path
        , text (Debug.toString model.redirection)]
    }
