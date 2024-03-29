port module Main exposing (Link, Model, Msg(..), Profile, Task, TaskList, changeTasks, decodeLink, decodeTask, decodeTaskList, init, initGapi, main, retInitGapi, retSignOut, signOut, subscriptions, update, view, viewChildTask, viewParentTask, viewTask, viewTaskList, viewTaskLists, viewTasks)

import Browser
import Browser.Navigation
import Dict exposing (..)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Http exposing (..)
import Json.Decode exposing (Decoder, bool, decodeString, field, list, maybe, nullable, string, succeed)
import Json.Decode.Pipeline exposing (hardcoded, optional, required)
import Json.Encode
import Url.Builder


port initGapi : () -> Cmd msg


port retInitGapi : (Profile -> msg) -> Sub msg


port signOut : () -> Cmd msg


port retSignOut : (Bool -> msg) -> Sub msg



-- JSON


decodeTaskList : Decoder TaskList
decodeTaskList =
    Json.Decode.map2 TaskList
        (field "id" string)
        (field "title" string)


decodeTask : Decoder Task
decodeTask =
    succeed Task
        |> required "kind" string
        |> required "id" string
        |> required "etag" string
        |> required "title" string
        |> required "updated" (nullable string)
        |> required "selfLink" string
        |> optional "parent" string ""
        |> required "position" string
        |> optional "notes" string ""
        |> required "status" string
        |> optional "due" string ""
        |> hardcoded ""
        |> optional "deleted" bool False
        |> optional "hidden" bool False



-- |> required "links" (list decodeLink)


decodeLink : Decoder Link
decodeLink =
    Json.Decode.map3 Link
        (field "typeName" string)
        (field "description" string)
        (field "link" string)


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
    , accessToken : String
    , apiKey : String
    }


type alias TaskList =
    { id : String
    , title : String
    }


type alias Link =
    { typeName : String
    , description : String
    , link : String
    }


type alias Task =
    { kind : String
    , id : String
    , etag : String
    , title : String
    , updated : Maybe String
    , selfLink : String
    , parent : String
    , position : String
    , notes : String
    , status : String
    , due : String
    , completed : String
    , deleted : Bool
    , hidden : Bool

    -- , links : List Link
    }


type alias Model =
    { profile : Profile
    , taskLists : List TaskList
    , parentTasks : List Task
    , selectedTaskListId : String
    , childTaskDict : Dict String (List Task)
    }


type Msg
    = Init
    | FinishInitGapi Profile
    | SignOut
    | FinishSignOut Bool
    | GetTaskList
    | GotTaskList (Result Http.Error String)
    | GetTask String
    | GotTask (Result Http.Error String)
    | ChangeDate Task String


init : () -> ( Model, Cmd Msg )
init _ =
    ( { profile =
            { name = ""
            , email = ""
            , accessToken = ""
            , apiKey = ""
            }
      , taskLists = []
      , parentTasks = []
      , childTaskDict = Dict.empty
      , selectedTaskListId = ""
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
            if profile.accessToken == "" then
                ( model
                , Browser.Navigation.load "/"
                )

            else
                update GetTaskList
                    { model
                        | profile = profile
                    }

        SignOut ->
            ( model, signOut () )

        FinishSignOut _ ->
            ( model, Browser.Navigation.load "/" )

        GetTaskList ->
            ( model
            , Http.request
                { method = "GET"
                , headers =
                    [ Http.header "Authorization" <| "Bearer " ++ model.profile.accessToken
                    ]
                , url =
                    Url.Builder.crossOrigin
                        "https://www.googleapis.com"
                        [ "tasks/v1/users/@me/lists?key=" ++ model.profile.apiKey ]
                        []
                , body = Http.emptyBody
                , expect = Http.expectString GotTaskList
                , timeout = Nothing
                , tracker = Nothing
                }
            )

        GotTaskList (Ok resp) ->
            let
                decodeResult =
                    decodeString (field "items" <| list decodeTaskList) resp
            in
            case decodeResult of
                Ok taskLists ->
                    ( { model
                        | taskLists = taskLists
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( model, Cmd.none )

        GotTaskList (Err error) ->
            ( model, Cmd.none )

        GetTask taskListId ->
            ( { model
                | selectedTaskListId = taskListId
              }
            , Http.request
                { method = "GET"
                , headers =
                    [ Http.header "Authorization" <| "Bearer " ++ model.profile.accessToken
                    ]
                , url =
                    Url.Builder.crossOrigin
                        "https://www.googleapis.com"
                        [ "tasks/v1/lists"
                        , taskListId
                        , "tasks?key=" ++ model.profile.apiKey
                        ]
                        []
                , body = Http.emptyBody
                , expect = Http.expectString GotTask
                , timeout = Nothing
                , tracker = Nothing
                }
            )

        GotTask (Ok resp) ->
            let
                decodeResult =
                    decodeString (field "items" <| list decodeTask) resp
            in
            case decodeResult of
                Ok tasks ->
                    let
                        ( parentTasks, childTaskDict ) =
                            changeTasks tasks
                    in
                    ( { model
                        | parentTasks = parentTasks
                        , childTaskDict = childTaskDict
                      }
                    , Cmd.none
                    )

                Err error ->
                    ( model, Cmd.none )

        GotTask (Err error) ->
            ( model, Cmd.none )

        ChangeDate task rfc3339 ->
            let
                newTask =
                    { task
                        | due = rfc3339
                    }
            in
            ( model
            , Http.request
                { method = "PUT"
                , headers =
                    [ Http.header "Authorization" <| "Bearer " ++ model.profile.accessToken
                    ]
                , url =
                    Url.Builder.crossOrigin
                        "https://www.googleapis.com"
                        [ "tasks/v1/lists"
                        , model.selectedTaskListId
                        , "tasks"
                        , task.id ++ "?key=" ++ model.profile.apiKey
                        ]
                        []
                , body = encodeTask newTask
                , expect = Http.expectString GotTask
                , timeout = Nothing
                , tracker = Nothing
                }
            )


changeTasks : List Task -> ( List Task, Dict String (List Task) )
changeTasks respTasks =
    let
        children =
            List.filter
                (\t -> t.parent /= "")
                respTasks

        resultParent =
            List.sortBy .position <|
                List.filter
                    (\t -> t.parent == "")
                    respTasks

        -- Dict 親ID 子Task
        childrenList =
            List.foldl
                (\c d ->
                    let
                        childList =
                            Maybe.withDefault [] <| Dict.get c.parent d

                        newChildList =
                            c :: childList
                    in
                    Dict.insert c.parent newChildList d
                )
                Dict.empty
                children

        -- 小タスクの並べ替え
        sortedChildrenList =
            Dict.map
                (\k v ->
                    List.sortBy .position v
                )
                childrenList
    in
    Tuple.pair resultParent sortedChildrenList


encodeTask : Task -> Body
encodeTask task =
    Http.jsonBody <|
        Json.Encode.object
            [ ( "kind", Json.Encode.string "tasks#task" )
            , ( "id", Json.Encode.string task.id )
            , ( "title", Json.Encode.string <| task.title )
            , ( "selfLink", Json.Encode.string task.selfLink )
            , ( "position", Json.Encode.string task.position )
            , ( "notes", Json.Encode.string task.notes )
            , ( "status", Json.Encode.string task.status )
            , ( "due", Json.Encode.string task.due )
            ]



-- VIEW


view : Model -> Html Msg
view model =
    article [ id "app" ]
        [ button [ onClick SignOut ] [ text "ログアウト" ]
        , div [] [ text model.profile.name ]
        , div [] [ text model.profile.email ]
        , div [ class "task-main" ]
            [ div [ class "task-lists" ] <| viewTaskLists model
            , div [ class "tasks" ] <| viewTasks model
            ]
        ]


viewTaskLists : Model -> List (Html Msg)
viewTaskLists model =
    List.map viewTaskList model.taskLists


viewTaskList : TaskList -> Html Msg
viewTaskList taskList =
    div [ onClick <| GetTask taskList.id ] [ text taskList.title ]


viewTasks : Model -> List (Html Msg)
viewTasks model =
    List.map (viewParentTask model.childTaskDict) model.parentTasks


viewParentTask : Dict String (List Task) -> Task -> Html Msg
viewParentTask childTaskDict parentTask =
    ul [] <|
        List.append
            [ li [] [ viewTask parentTask ] ]
        <|
            List.map viewChildTask <|
                Maybe.withDefault [] <|
                    Dict.get parentTask.id childTaskDict


viewChildTask : Task -> Html Msg
viewChildTask childTask =
    ul []
        [ li []
            [ viewTask childTask ]
        ]


viewTask : Task -> Html Msg
viewTask task =
    div []
        [ div []
            [ input [ type_ "checkbox" ] []
            , text <| task.title
            ]
        , div []
            [ node "rfc3339-date"
                [ attribute "rfc3339" task.due
                , on "dateChange" <|
                    Json.Decode.map (ChangeDate task) <|
                        field "detail" string
                ]
                []
            ]
        ]
