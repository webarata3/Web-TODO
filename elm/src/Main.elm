port module Main exposing (Model, Msg(..), init, initGapi, main, retInitGapi, retSignOut, signOut, subscriptions, update, view)

import Browser
import Browser.Navigation
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import Json.Decode exposing (Decoder, decodeString, field, list, string)


port initGapi : () -> Cmd msg


port retInitGapi : (Profile -> msg) -> Sub msg


port signOut : () -> Cmd msg


port retSignOut : (Bool -> msg) -> Sub msg


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , update = update
        , view = view
        , subscriptions = subscriptions
        }



-- MODEL


type alias Profile =
    { name : String
    , email : String
    }


type alias Model =
    { profile : Profile
    }


type Msg
    = Init
    | FinishInitGapi Profile
    | SignOut
    | FinishSignOut Bool


init : () -> ( Model, Cmd Msg )
init _ =
    ( { profile = { name = "", email = "" }
      }
    , initGapi ()
    )


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ retInitGapi FinishInitGapi
        , retSignOut FinishSignOut
        ]



-- UPDATE


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Init ->
            ( model, initGapi () )

        FinishInitGapi profile ->
            if profile.name == "" then
                ( model
                , Browser.Navigation.load "/"
                )

            else
                ( { model
                    | profile = profile
                  }
                , Cmd.none
                )

        SignOut ->
            ( model, signOut () )

        FinishSignOut _ ->
            ( model, Browser.Navigation.load "/" )



-- VIEW


view : Model -> Html Msg
view model =
    article [ id "app" ]
        [ button [ onClick SignOut ] [ text "ログアウト" ]
        , div [] [ text model.profile.name ]
        , div [] [ text model.profile.email ]
        ]
