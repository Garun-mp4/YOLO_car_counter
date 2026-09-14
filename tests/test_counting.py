from yolo_car_counter.counting import Detection, LineCrossingCounter, aggregate_category_counts


def detection(track_id: int, center_y: float, class_name: str = "car") -> Detection:
    return Detection(
        track_id=track_id,
        class_name=class_name,
        confidence=0.9,
        x1=10,
        y1=center_y - 10,
        x2=110,
        y2=center_y + 10,
    )


def test_counts_track_after_start_and_finish_crossings() -> None:
    counter = LineCrossingCounter(start_line_y=100, finish_line_y=200, direction="down")

    counter.update([detection(7, 50)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(7, 130)], frame_index=1, timestamp_seconds=1.0)
    events = counter.update([detection(7, 220)], frame_index=2, timestamp_seconds=2.0)
    counter.update([detection(7, 240)], frame_index=3, timestamp_seconds=3.0)

    assert len(events) == 1
    assert counter.total_count == 1
    assert counter.class_counts == {"car": 1}
    assert events[0].track_id == 7


def test_does_not_count_track_that_appeared_after_start_line() -> None:
    counter = LineCrossingCounter(start_line_y=100, finish_line_y=200, direction="down")

    counter.update([detection(3, 150)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(3, 220)], frame_index=1, timestamp_seconds=1.0)

    assert counter.total_count == 0


def test_does_not_count_same_track_twice() -> None:
    counter = LineCrossingCounter(start_line_y=100, finish_line_y=200, direction="down")

    counter.update([detection(1, 50)], frame_index=0, timestamp_seconds=0.0)
    counter.update([detection(1, 120)], frame_index=1, timestamp_seconds=1.0)
    counter.update([detection(1, 220)], frame_index=2, timestamp_seconds=2.0)
    counter.update([detection(1, 150)], frame_index=3, timestamp_seconds=3.0)
    counter.update([detection(1, 230)], frame_index=4, timestamp_seconds=4.0)

    assert counter.total_count == 1


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
