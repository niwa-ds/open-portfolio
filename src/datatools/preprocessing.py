import pandas as pd


def get_binary_cols(df: pd.DataFrame) -> list[str]:
    """
    Identify binary columns in a DataFrame.

    A column is considered binary if:
    - its dtype is boolean, or
    - its non-null values consist only of {0, 1}.

    Parameters
    ----------
    df : pd.DataFrame
        Input DataFrame.

    Returns
    -------
    list[str]
        List of column names identified as binary variables.
    """
    binary_cols = []

    for col in df.columns:
        s = df[col]

        if not (
            pd.api.types.is_bool_dtype(s) or pd.api.types.is_numeric_dtype(s)
        ):
            continue

        u = pd.unique(s.dropna())
        if len(u) == 0:
            continue

        if pd.api.types.is_bool_dtype(s) or set(u).issubset({0, 1}):
            binary_cols.append(col)

    return binary_cols
