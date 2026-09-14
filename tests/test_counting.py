from yolo_car_counter.counting import Detection, LineCrossingCounter, aggregate_category_counts


def detection(
    track_id: int,
    bottom_y: float,
    class_name: str = "car",
    confidence: float = 0.9,
) -> Detection:
    return Detection(
        track_id=track_id,
        class_name=class_name,
        confidence=confidence,
        x1=10,
        y1=bottom_y - 40,
        x2=110,
        y2=bottom_y,
    )


def test_counts_track_when_it_crosses_finish_without_start_line() -> None:
    counter = LineCrossingCounter(finish_line_y=200, direction="down")

    counter.update([detection(7, 150)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(7, 190)], frame_index=1, timestamp_seconds=1.0)
    events = counter.update([detection(7, 220)], frame_index=2, timestamp_seconds=2.0)

    assert len(events) == 1
    assert counter.total_count == 1
    assert counter.class_counts == {"car": 1}
    assert events[0].track_id == 7
    assert events[0].reason == "line_crossing"


def test_counts_upward_track_when_it_crosses_finish_line() -> None:
    counter = LineCrossingCounter(finish_line_y=200, direction="up")

    counter.update([detection(11, 250)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(11, 215)], frame_index=1, timestamp_seconds=1.0)
    events = counter.update([detection(11, 180)], frame_index=2, timestamp_seconds=2.0)

    assert len(events) == 1
    assert events[0].direction == "up"
    assert counter.class_counts == {"car": 1}


def test_counts_when_track_starts_exactly_on_finish_line() -> None:
    counter = LineCrossingCounter(finish_line_y=200, direction="down")

    counter.update([detection(12, 200)], frame_index=0, timestamp_seconds=0.0)
    events = counter.update([detection(12, 220)], frame_index=1, timestamp_seconds=1.0)

    assert len(events) == 1
    assert events[0].reason == "line_crossing"


def test_counts_track_that_appeared_below_finish_when_it_exits() -> None:
    counter = LineCrossingCounter(
        finish_line_y=200,
        direction="down",
        max_missing_frames=2,
        min_track_observations=2,
    )

    counter.update([detection(3, 215)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(3, 240)], frame_index=1, timestamp_seconds=1.0)
    counter.update([], frame_index=2, timestamp_seconds=2.0)
    events = counter.update([], frame_index=3, timestamp_seconds=3.0)

    assert len(events) == 1
    assert events[0].reason == "exit"
    assert counter.total_count == 1


def test_counts_track_lost_just_before_finish_when_motion_predicts_crossing() -> None:
    counter = LineCrossingCounter(
        finish_line_y=200,
        direction="down",
        max_missing_frames=2,
        min_track_observations=2,
        exit_margin_y=30,
    )

    counter.update([detection(4, 150)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(4, 190)], frame_index=1, timestamp_seconds=1.0)
    counter.update([], frame_index=2, timestamp_seconds=2.0)
    events = counter.update([], frame_index=3, timestamp_seconds=3.0)

    assert len(events) == 1
    assert events[0].reason == "exit"


def test_does_not_count_track_lost_far_from_finish() -> None:
    counter = LineCrossingCounter(
        finish_line_y=200,
        direction="down",
        max_missing_frames=2,
        min_track_observations=2,
    )

    counter.update([detection(5, 80)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(5, 100)], frame_index=1, timestamp_seconds=1.0)
    counter.update([], frame_index=2, timestamp_seconds=2.0)
    counter.update([], frame_index=3, timestamp_seconds=3.0)

    assert counter.total_count == 0


def test_same_track_is_not_counted_twice() -> None:
    counter = LineCrossingCounter(finish_line_y=200, direction="down")

    counter.update([detection(1, 150)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(1, 220)], frame_index=1, timestamp_seconds=1.0)
    counter.update([detection(1, 150)], frame_index=2, timestamp_seconds=2.0)
    counter.update([detection(1, 230)], frame_index=3, timestamp_seconds=3.0)

    assert counter.total_count == 1


def test_short_tracker_id_switch_keeps_one_vehicle_identity() -> None:
    counter = LineCrossingCounter(finish_line_y=200, direction="down")

    counter.update([detection(1, 150)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(1, 180)], frame_index=1, timestamp_seconds=1.0)
    events = counter.update([detection(2, 220)], frame_index=2, timestamp_seconds=2.0)

    assert len(events) == 1
    assert counter.total_count == 1


def test_class_is_stabilized_by_weighted_track_history() -> None:
    counter = LineCrossingCounter(finish_line_y=200, direction="down")

    for frame_index, bottom_y in enumerate((120, 140, 160, 180)):
        counter.update([detection(8, bottom_y, "car", 0.8)], frame_index, float(frame_index))
    counter.update([detection(8, 220, "truck", 0.99)], frame_index=4, timestamp_seconds=4.0)

    assert counter.class_counts == {"car": 1}
    assert counter.class_name_for(8) == "car"


def test_class_can_change_after_sustained_new_evidence() -> None:
    counter = LineCrossingCounter(finish_line_y=500, direction="down")

    for frame_index, bottom_y in enumerate((120, 140, 160)):
        counter.update([detection(9, bottom_y, "car", 0.8)], frame_index, float(frame_index))
    for frame_index, bottom_y in enumerate((180, 200, 220), start=3):
        counter.update([detection(9, bottom_y, "motorcycle", 0.8)], frame_index, float(frame_index))

    assert counter.class_name_for(9) == "motorcycle"


def test_aggregates_four_vehicle_families_for_dashboard() -> None:
    class_counts = {
        "car": 8,
        "bicycle": 2,
        "motorcycle": 3,
        "bus": 1,
        "truck": 4,
    }
    mode_groups = {
        "all": ("bicycle", "car", "motorcycle", "bus", "truck"),
        "cars": ("car",),
        "two_wheelers": ("bicycle", "motorcycle"),
        "heavy": ("bus", "truck"),
    }

    assert aggregate_category_counts(class_counts, mode_groups) == {
        "all": 18,
        "cars": 8,
        "two_wheelers": 5,
        "heavy": 5,
    }
