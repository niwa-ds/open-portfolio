import pandas as pd

from datatools.preprocessing import get_binary_cols


def test_get_binary_cols():
    df = pd.DataFrame({
        'a': [0, 1, 0, 1],
        'b': [True, False, False, True],
        'c': [1, 2, 3, 4],
        'd': ['x', 'y', 'z', 'm'],
    })

    result = set(get_binary_cols(df))
    assert result == {'a', 'b'}


def test_get_binary_cols_ignores_non_0_1_numeric():
    df = pd.DataFrame({
        'x': [0, 2, 1, 0],
        'y': [True, False, True, True],
    })

    result = set(get_binary_cols(df))
    assert 'y' in result
    assert 'x' not in result
