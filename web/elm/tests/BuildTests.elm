module BuildTests exposing (all)

import Array
import Build
import Build.Effects as Effects
import Build.Msgs as Msgs
import Concourse
import Concourse.BuildEvents as BuildEvents
import DashboardTests
    exposing
        ( defineHoverBehaviour
        , iconSelector
        , middleGrey
        )
import Date
import Dict
import Expect
import Html.Attributes as Attr
import Test exposing (..)
import Test.Html.Query as Query
import Test.Html.Selector
    exposing
        ( attribute
        , class
        , containing
        , id
        , style
        , text
        )


all : Test
all =
    describe "build page" <|
        let
            pageLoad =
                Build.init
                    { title = always Cmd.none
                    }
                    { csrfToken = ""
                    , hash = ""
                    }
                    (Build.JobBuildPage
                        { teamName = "team"
                        , pipelineName = "pipeline"
                        , jobName = "job"
                        , buildName = "1"
                        }
                    )

            theBuild : Concourse.Build
            theBuild =
                { id = 1
                , name = "1"
                , job =
                    Just
                        { teamName = "team"
                        , pipelineName = "pipeline"
                        , jobName = "job"
                        }
                , status = Concourse.BuildStatusSucceeded
                , duration =
                    { startedAt = Nothing
                    , finishedAt = Nothing
                    }
                , reapTime = Nothing
                }

            startedBuild : Concourse.Build
            startedBuild =
                { id = 1
                , name = "1"
                , job =
                    Just
                        { teamName = "team"
                        , pipelineName = "pipeline"
                        , jobName = "job"
                        }
                , status = Concourse.BuildStatusStarted
                , duration =
                    { startedAt = Nothing
                    , finishedAt = Nothing
                    }
                , reapTime = Nothing
                }

            fetchBuild : Build.Model -> ( Build.Model, List Effects.Effect )
            fetchBuild =
                Build.update <| Msgs.BuildFetched 1 <| Ok theBuild

            fetchStartedBuild :
                Build.Model
                -> ( Build.Model, List Effects.Effect )
            fetchStartedBuild =
                Build.update <| Msgs.BuildFetched 1 <| Ok startedBuild

            fetchJobDetails : Build.Model -> ( Build.Model, List Effects.Effect )
            fetchJobDetails =
                Build.update <|
                    Msgs.BuildJobDetailsFetched <|
                        Ok
                            { pipeline =
                                { teamName = "team"
                                , pipelineName = "pipeline"
                                }
                            , name = "job"
                            , pipelineName = "pipeline"
                            , teamName = "team"
                            , nextBuild = Nothing
                            , finishedBuild = Nothing
                            , transitionBuild = Nothing
                            , paused = False
                            , disableManualTrigger = False
                            , inputs = []
                            , outputs = []
                            , groups = []
                            }

            fetchJobDetailsNoTrigger :
                Build.Model
                -> ( Build.Model, List Effects.Effect )
            fetchJobDetailsNoTrigger =
                Build.update <|
                    Msgs.BuildJobDetailsFetched <|
                        Ok
                            { pipeline =
                                { teamName = "team"
                                , pipelineName = "pipeline"
                                }
                            , name = "job"
                            , pipelineName = "pipeline"
                            , teamName = "team"
                            , nextBuild = Nothing
                            , finishedBuild = Nothing
                            , transitionBuild = Nothing
                            , paused = False
                            , disableManualTrigger = True
                            , inputs = []
                            , outputs = []
                            , groups = []
                            }

            fetchHistory : Build.Model -> ( Build.Model, List Effects.Effect )
            fetchHistory =
                Build.update
                    (Msgs.BuildHistoryFetched
                        (Ok
                            { pagination =
                                { previousPage = Nothing
                                , nextPage = Nothing
                                }
                            , content = [ theBuild ]
                            }
                        )
                    )
        in
        [ test "says loading on page load" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.has [ text "loading" ]
        , test "fetches build on page load" <|
            \_ ->
                pageLoad
                    |> Tuple.second
                    |> Expect.equal
                        [ Effects.FetchJobBuild 1
                            { teamName = "team"
                            , pipelineName = "pipeline"
                            , jobName = "job"
                            , buildName = "1"
                            }
                        , Effects.GetCurrentTime
                        ]
        , test "has a header after the build is fetched" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.has [ id "build-header" ]
        , test "fetches build history and job details after build is fetched" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.second
                    |> Expect.all
                        [ List.member
                            (Effects.FetchBuildHistory
                                { teamName = "team"
                                , pipelineName = "pipeline"
                                , jobName = "job"
                                }
                                Nothing
                            )
                            >> Expect.true
                                "expected effect was not in the list"
                        , List.member
                            (Effects.FetchBuildJobDetails
                                { teamName = "team"
                                , pipelineName = "pipeline"
                                , jobName = "job"
                                }
                            )
                            >> Expect.true
                                "expected effect was not in the list"
                        ]
        , test "header lays out horizontally" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find [ id "build-header" ]
                    |> Query.has
                        [ style [ ( "display", "flex" ) ] ]
        , test "header spreads out contents" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find [ id "build-header" ]
                    |> Query.has
                        [ style [ ( "justify-content", "space-between" ) ] ]
        , test
            ("trigger build button on right side of header "
                ++ "after history and job details fetched"
            )
          <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find [ id "build-header" ]
                    |> Query.children []
                    |> Query.index -1
                    |> Query.has
                        [ attribute <|
                            Attr.attribute "aria-label" "Trigger Build"
                        ]
        , test "trigger build button has dark grey background" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Trigger Build"
                        ]
                    |> Query.has
                        [ style
                            [ ( "padding", "10px" )
                            , ( "border", "none" )
                            , ( "background-color", middleGrey )
                            , ( "outline", "none" )
                            ]
                        ]
        , test
            ("when manual triggering is disabled, "
                ++ "trigger build button has default cursor"
            )
          <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetailsNoTrigger
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Trigger Build"
                        ]
                    |> Query.has [ style [ ( "cursor", "default" ) ] ]
        , test "trigger build button has pointer cursor" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Trigger Build"
                        ]
                    |> Query.has [ style [ ( "cursor", "pointer" ) ] ]
        , test "trigger build button has 'plus' icon" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Trigger Build"
                        ]
                    |> Query.children []
                    |> Query.first
                    |> Query.has
                        (iconSelector
                            { size = "40px"
                            , image = "ic_add_circle_outline_white.svg"
                            }
                        )
        , defineHoverBehaviour
            { name = "trigger build button"
            , setup =
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
            , query =
                Build.view
                    >> Query.fromHtml
                    >> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Trigger Build"
                        ]
            , updateFunc = \msg -> Build.update msg >> Tuple.first
            , unhoveredSelector =
                { description = "grey plus icon"
                , selector =
                    [ style [ ( "opacity", "0.5" ) ] ]
                        ++ iconSelector
                            { size = "40px"
                            , image = "ic_add_circle_outline_white.svg"
                            }
                }
            , hoveredSelector =
                { description = "white plus icon"
                , selector =
                    [ style [ ( "opacity", "1" ) ] ]
                        ++ iconSelector
                            { size = "40px"
                            , image = "ic_add_circle_outline_white.svg"
                            }
                }
            , mouseEnterMsg = Msgs.Hover Msgs.Trigger
            , mouseLeaveMsg = Msgs.Hover Msgs.Neither
            }
        , defineHoverBehaviour
            { name = "disabled trigger build button"
            , setup =
                pageLoad
                    |> Tuple.first
                    |> fetchBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetailsNoTrigger
                    |> Tuple.first
            , query =
                Build.view
                    >> Query.fromHtml
                    >> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Trigger Build"
                        ]
            , updateFunc = \msg -> Build.update msg >> Tuple.first
            , unhoveredSelector =
                { description = "grey plus icon"
                , selector =
                    [ style [ ( "opacity", "0.5" ) ] ]
                        ++ iconSelector
                            { size = "40px"
                            , image = "ic_add_circle_outline_white.svg"
                            }
                }
            , hoveredSelector =
                { description = "grey plus icon with tooltip"
                , selector =
                    [ style [ ( "position", "relative" ) ]
                    , containing
                        [ containing
                            [ text "manual triggering disabled in job config" ]
                        , style
                            [ ( "position", "absolute" )
                            , ( "right", "100%" )
                            , ( "top", "15px" )
                            , ( "width", "300px" )
                            , ( "color", "#ecf0f1" )
                            , ( "font-size", "12px" )
                            , ( "font-family", "Inconsolata,monospace" )
                            , ( "padding", "10px" )
                            , ( "text-align", "right" )
                            ]
                        ]
                    , containing <|
                        [ style
                            [ ( "opacity", "0.5" )
                            ]
                        ]
                            ++ iconSelector
                                { size = "40px"
                                , image = "ic_add_circle_outline_white.svg"
                                }
                    ]
                }
            , mouseEnterMsg = Msgs.Hover Msgs.Trigger
            , mouseLeaveMsg = Msgs.Hover Msgs.Neither
            }
        , test "build action section lays out horizontally" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchStartedBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find [ id "build-header" ]
                    |> Query.children []
                    |> Query.index -1
                    |> Query.has [ style [ ( "display", "flex" ) ] ]
        , test "abort build button is to the left of the trigger button" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchStartedBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find [ id "build-header" ]
                    |> Query.children []
                    |> Query.index -1
                    |> Query.children []
                    |> Query.first
                    |> Query.has
                        [ attribute <|
                            Attr.attribute "aria-label" "Abort Build"
                        ]
        , test "abort build button has dark grey background" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchStartedBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Abort Build"
                        ]
                    |> Query.has
                        [ style
                            [ ( "padding", "10px" )
                            , ( "border", "none" )
                            , ( "background-color", middleGrey )
                            , ( "outline", "none" )
                            ]
                        ]
        , test "abort build button has pointer cursor" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchStartedBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Abort Build"
                        ]
                    |> Query.has [ style [ ( "cursor", "pointer" ) ] ]
        , test "abort build button has 'X' icon" <|
            \_ ->
                pageLoad
                    |> Tuple.first
                    |> fetchStartedBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
                    |> Build.view
                    |> Query.fromHtml
                    |> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Abort Build"
                        ]
                    |> Query.children []
                    |> Query.first
                    |> Query.has
                        (iconSelector
                            { size = "40px"
                            , image = "ic_abort_circle_outline_white.svg"
                            }
                        )
        , defineHoverBehaviour
            { name = "abort build button"
            , setup =
                pageLoad
                    |> Tuple.first
                    |> fetchStartedBuild
                    |> Tuple.first
                    |> fetchHistory
                    |> Tuple.first
                    |> fetchJobDetails
                    |> Tuple.first
            , query =
                Build.view
                    >> Query.fromHtml
                    >> Query.find
                        [ attribute <|
                            Attr.attribute "aria-label" "Abort Build"
                        ]
            , updateFunc = \msg -> Build.update msg >> Tuple.first
            , unhoveredSelector =
                { description = "grey abort icon"
                , selector =
                    [ style [ ( "opacity", "0.5" ) ] ]
                        ++ iconSelector
                            { size = "40px"
                            , image = "ic_abort_circle_outline_white.svg"
                            }
                }
            , hoveredSelector =
                { description = "white abort icon"
                , selector =
                    [ style [ ( "opacity", "1" ) ] ]
                        ++ iconSelector
                            { size = "40px"
                            , image = "ic_abort_circle_outline_white.svg"
                            }
                }
            , mouseEnterMsg = Msgs.Hover Msgs.Abort
            , mouseLeaveMsg = Msgs.Hover Msgs.Neither
            }
        , describe "step header" <|
            let
                setup : () -> Build.Model
                setup _ =
                    pageLoad
                        |> Tuple.first
                        |> fetchStartedBuild
                        |> Tuple.first
                        |> fetchHistory
                        |> Tuple.first
                        |> fetchJobDetails
                        |> Tuple.first
                        |> Build.update
                            (Msgs.PlanAndResourcesFetched <|
                                Ok <|
                                    ( { id = "plan"
                                      , step =
                                            Concourse.BuildStepGet
                                                "step"
                                                Nothing
                                      }
                                    , { inputs = [], outputs = [] }
                                    )
                            )
                        |> Tuple.first
            in
            [ test "build step header lays out horizontally" <|
                setup
                    >> Build.view
                    >> Query.fromHtml
                    >> Query.find [ class "header" ]
                    >> Query.has [ style [ ( "display", "flex" ) ] ]
            , test "has two children spread apart" <|
                setup
                    >> Build.view
                    >> Query.fromHtml
                    >> Query.find [ class "header" ]
                    >> Expect.all
                        [ Query.has
                            [ style
                                [ ( "justify-content", "space-between" ) ]
                            ]
                        , Query.children [] >> Query.count (Expect.equal 2)
                        ]
            , test "first child lays out horizontally" <|
                setup
                    >> Build.view
                    >> Query.fromHtml
                    >> Query.find [ class "header" ]
                    >> Query.children []
                    >> Query.first
                    >> Query.has [ style [ ( "display", "flex" ) ] ]
            , test "resource get step shows downward arrow" <|
                setup
                    >> Build.view
                    >> Query.fromHtml
                    >> Query.has
                        (iconSelector
                            { size = "28px"
                            , image = "ic_arrow_downward.svg"
                            }
                            ++ [ style [ ( "background-size", "14px 14px" ) ] ]
                        )
            , test "task step shows terminal icon" <|
                \_ ->
                    pageLoad
                        |> Tuple.first
                        |> fetchStartedBuild
                        |> Tuple.first
                        |> fetchHistory
                        |> Tuple.first
                        |> fetchJobDetails
                        |> Tuple.first
                        |> Build.update
                            (Msgs.PlanAndResourcesFetched <|
                                Ok <|
                                    ( { id = "plan"
                                      , step =
                                            Concourse.BuildStepTask
                                                "step"
                                      }
                                    , { inputs = [], outputs = [] }
                                    )
                            )
                        |> Tuple.first
                        |> Build.view
                        |> Query.fromHtml
                        |> Query.has
                            (iconSelector
                                { size = "28px"
                                , image = "ic_terminal.svg"
                                }
                                ++ [ style
                                        [ ( "background-size", "14px 14px" ) ]
                                   ]
                            )
            , test "put step shows upward arrow" <|
                \_ ->
                    pageLoad
                        |> Tuple.first
                        |> fetchStartedBuild
                        |> Tuple.first
                        |> fetchHistory
                        |> Tuple.first
                        |> fetchJobDetails
                        |> Tuple.first
                        |> Build.update
                            (Msgs.PlanAndResourcesFetched <|
                                Ok <|
                                    ( { id = "plan"
                                      , step = Concourse.BuildStepPut "step"
                                      }
                                    , { inputs = [], outputs = [] }
                                    )
                            )
                        |> Tuple.first
                        |> Build.view
                        |> Query.fromHtml
                        |> Query.has
                            (iconSelector
                                { size = "28px"
                                , image = "ic_arrow_upward.svg"
                                }
                                ++ [ style
                                        [ ( "background-size", "14px 14px" ) ]
                                   ]
                            )
            , test "successful step has a checkmark at the far right" <|
                setup
                    >> Build.update (Msgs.BuildEventsMsg BuildEvents.Opened)
                    >> Tuple.first
                    >> Build.update
                        (Msgs.BuildEventsMsg <|
                            BuildEvents.Events <|
                                Ok <|
                                    Array.fromList
                                        [ BuildEvents.FinishGet
                                            { source = "stdout", id = "plan" }
                                            0
                                            Dict.empty
                                            []
                                        ]
                        )
                    >> Tuple.first
                    >> Build.view
                    >> Query.fromHtml
                    >> Query.find [ class "header" ]
                    >> Query.children []
                    >> Query.index -1
                    >> Query.has
                        (iconSelector
                            { size = "28px"
                            , image = "ic-success-check.svg"
                            }
                            ++ [ style [ ( "background-size", "14px 14px" ) ] ]
                        )
            , test "failing step has an X at the far right" <|
                setup
                    >> Build.update (Msgs.BuildEventsMsg BuildEvents.Opened)
                    >> Tuple.first
                    >> Build.update
                        (Msgs.BuildEventsMsg <|
                            BuildEvents.Events <|
                                Ok <|
                                    Array.fromList
                                        [ BuildEvents.FinishGet
                                            { source = "stdout", id = "plan" }
                                            1
                                            Dict.empty
                                            []
                                        ]
                        )
                    >> Tuple.first
                    >> Build.view
                    >> Query.fromHtml
                    >> Query.find [ class "header" ]
                    >> Query.children []
                    >> Query.index -1
                    >> Query.has
                        (iconSelector
                            { size = "28px"
                            , image = "ic-failure-times.svg"
                            }
                            ++ [ style [ ( "background-size", "14px 14px" ) ] ]
                        )
            , test "erroring step has orange exclamation triangle at right" <|
                setup
                    >> Build.update (Msgs.BuildEventsMsg BuildEvents.Opened)
                    >> Tuple.first
                    >> Build.update
                        (Msgs.BuildEventsMsg <|
                            BuildEvents.Events <|
                                Ok <|
                                    Array.fromList
                                        [ BuildEvents.Error
                                            { source = "stderr", id = "plan" }
                                            "error message"
                                        ]
                        )
                    >> Tuple.first
                    >> Build.view
                    >> Query.fromHtml
                    >> Query.find [ class "header" ]
                    >> Query.children []
                    >> Query.index -1
                    >> Query.has
                        (iconSelector
                            { size = "28px"
                            , image = "ic_exclamation-triangle.svg"
                            }
                            ++ [ style [ ( "background-size", "14px 14px" ) ] ]
                        )
            ]
        ]
