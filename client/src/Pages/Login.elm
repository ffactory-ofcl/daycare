port module Pages.Login exposing (LoadState(..), Model, Msg(..), decodeUserLogin, encodeUserLogin, init, login, subscriptions, update, view, viewLoginForm)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput, onSubmit)
import Http
import Json.Decode as D
import Json.Encode as E
import Route
import Session exposing (Session)



-- Model


init : Session -> ( Model, Cmd Msg )
init session =
    ( { session = session
      , identifier = ""
      , password = ""
      , state = LoginStateIdle
      }
    , Cmd.none
    )


type alias Model =
    { session : Session
    , identifier : String
    , password : String
    , state : LoadState
    }


type LoadState
    = LoginStateIdle
    | LoginStateWait
    | LoginStateError Http.Error
    | LoginStateSuccess String



-- View


view : Model -> List (Html Msg)
view model =
    let
        append =
            case model.state of
                LoginStateWait ->
                    span [ class "login wait-text" ] [ text "..." ]

                LoginStateSuccess _ ->
                    span [ class "login success-text" ] [ text "Success!" ]

                LoginStateError Http.NetworkError ->
                    span [ class "login error-text" ] [ text "Cannot reach Server" ]

                LoginStateError (Http.BadStatus 401) ->
                    span [ class "login error-text" ] [ text "Wrong identifier or password" ]

                LoginStateError _ ->
                    span [ class "login error-text" ] [ text "An error occurred. Please retry." ]

                LoginStateIdle ->
                    text ""
    in
    [ div [ class "login container" ] [ viewLoginForm model append ] ]


viewLoginForm : Model -> Html Msg -> Html Msg
viewLoginForm model appendix =
    Html.form [ class "login form", onSubmit UserLoginLoad ]
        [ h3 [ class "login header" ] [ text "LOGIN" ]

        -- , label [ class "login identifier" ] [ text "identifier:" ]
        , input [ class "login identifier", placeholder "username / email", value model.identifier, onInput UpdateIdentifier, autofocus True, autocomplete True ] []

        -- , label [ class "login password" ] [ text "Password:" ]
        , input [ class "login password", placeholder "password", type_ "password", value model.password, onInput UpdatePassword ] []
        , button [ class "login submit", type_ "submit" ] [ text "Login" ]
        , div [ class "login appendix" ] [ appendix ]
        ]



-- Update


type Msg
    = UserLoginLoad
    | UserLoginLoaded (Result Http.Error String)
    | UpdateIdentifier String
    | UpdatePassword String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UserLoginLoad ->
            ( { model | state = LoginStateWait }, login model )

        UserLoginLoaded (Ok token) ->
            let
                key =
                    Session.navKey model.session
            in
            if token /= "" then
                ( { model | session = Session.fromString key (Just token) }
                , Cmd.batch [ saveTokenLogin token, Route.replaceUrl key Route.App ]
                )

            else
                ( model, Cmd.none )

        UserLoginLoaded (Err message) ->
            ( { model | state = LoginStateError message }, Cmd.none )

        UpdateIdentifier i ->
            ( { model | identifier = i }, Cmd.none )

        UpdatePassword p ->
            ( { model | password = p }, Cmd.none )



-- _ ->
--     ( model, Cmd.none )
--HTTP


login : Model -> Cmd Msg
login model =
    Http.post
        { url = "/api/v3/login"
        , body = Http.jsonBody (encodeUserLogin model)
        , expect = Http.expectJson UserLoginLoaded decodeUserLogin
        }



-- Json


encodeUserLogin : Model -> E.Value
encodeUserLogin model =
    let
        key =
            if String.contains "@" model.identifier then
                "email"

            else
                "username"
    in
    E.object
        [ ( key, E.string model.identifier )
        , ( "password", E.string model.password )
        ]


decodeUserLogin : D.Decoder String
decodeUserLogin =
    D.field "token" D.string



{- PORTS -}


subscriptions : Model -> Sub Msg
subscriptions model =
    loadedTokenLogin (\t -> UserLoginLoaded <| Ok t)


port loadedTokenLogin : (String -> msg) -> Sub msg


port saveTokenLogin : String -> Cmd msg
