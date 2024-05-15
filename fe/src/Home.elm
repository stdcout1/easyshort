module Home exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Navigation as Nav
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Encode as Encode
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


type ResultURL
    = Start
    | Waiting
    | Complete String


type alias Model =
    { key : Nav.Key
    , url : Url.Url
    , query : String
    , custom : Maybe String
    , shortened : ResultURL
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    ( { key = key
      , url = url
      , query = "https://google.com"
      , shortened = Start
      , custom = Nothing
      }
    , Cmd.none
    )



-- UPDATE


type Msg
    = LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url
    | UpdateInput String
    | UpdateCustom String
    | SubmitInput
    | Recived (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateInput string ->
            ( { model | query = string }, Cmd.none )

        UpdateCustom string ->
            ( { model | custom = Just string }, Cmd.none )

        SubmitInput ->
            ( { model | shortened = Waiting }, postLink model.query model.custom )

        Recived result ->
            ( { model
                | shortened =
                    Complete
                        (case result of
                            Err err ->
                                "Error: " ++ Debug.toString err

                            Ok string ->
                                string
                        )
              }
            , Cmd.none
            )

        _ ->
            ( model, Cmd.none )


postLink : String -> Maybe String -> Cmd Msg
postLink query custom =
    let
        item : Encode.Value
        item =
            Encode.object
                (( "link", Encode.string query )
                    :: (case custom of
                            Nothing ->
                                []

                            Just string ->
                                [ ( "preffered_url", Encode.string string ) ]
                       )
                )
    in
    Http.post
        { url = "http://172.245.42.218:3000/create_link"
        , body = Http.jsonBody item
        , expect = Http.expectString Recived
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Browser.Document Msg
view model =
    { title = "sh"
    , body =
        [ div [ class "container mx-auto p-2"]
            [ div [ class "mb-3" ]
                [ label [ class "form-label" ] [ text "Paste a long url: " ]
                , Html.input [ class "form-control", onInput UpdateInput, placeholder model.query ] []
                ]
            , div [ class "mb-3"]
                [ label [ class "form-label" ] [ text "Custom link: " ]
                , Html.input [ class "form-control", onInput UpdateCustom, placeholder "Optional" ] []
                ]
            , Html.button [class "btn btn-primary mt-3", onClick SubmitInput ] [ text "Shorten" ]
            , viewResult model
            , model.custom |> Maybe.withDefault "Empty" |> text
            , text model.query
            ]
        ]
    }


viewResult : Model -> Html msg
viewResult model =
    p []
        [ text
            (case model.shortened of
                Start ->
                    "Click submit to get a link!"

                Waiting ->
                    "Loading..."

                Complete string ->
                    "sh.nasirk.ca/" ++ string
            )
        ]
