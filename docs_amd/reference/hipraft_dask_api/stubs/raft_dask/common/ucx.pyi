# MIT License
#
# Copyright (C) 2026 Advanced Micro Devices, Inc. All rights reserved.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

from __future__ import annotations
import ucxx as ucxx
__all__: list[str] = ['UCX', 'ucxx']
class UCX:
    """

        Singleton UCX context to encapsulate all interactions with the
        UCXX API and guarantee only a single listener & endpoints are
        created by RAFT Comms on a single process.

    """
    _UCX__instance = None
    @staticmethod
    def get(listener_callback = _connection_func):
        ...
    def __del__(self):
        ...
    def __init__(self, listener_callback):
        ...
    def _create_endpoint(self, ip, port):
        ...
    def _create_listener(self):
        ...
    def add_server_endpoint(self, ep):
        ...
    def close_endpoints(self):
        ...
    def get_endpoint(self, ip, port):
        ...
    def get_worker(self):
        ...
    def listener_port(self):
        ...
def _connection_func(ep):
    ...
