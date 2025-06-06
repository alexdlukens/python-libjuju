# Copyright 2023 Canonical Ltd.
# Licensed under the Apache V2, see LICENCE file for details.

import unittest
from unittest import mock

import pytest

from juju.client.jujudata import FileJujuData
from juju.errors import JujuControllerNotFoundError


class TestJujuData(unittest.IsolatedAsyncioTestCase):
    @mock.patch("yaml.load")
    async def test_verify_controller_uninitialized(self, yaml_load):
        yaml_load.side_effect = FileNotFoundError()
        jujudata = FileJujuData()
        with pytest.raises(JujuControllerNotFoundError):
            jujudata.current_controller()
