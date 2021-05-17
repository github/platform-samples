from __future__ import print_function

from wsgiref.simple_server import make_server
from pyramid.config import Configurator
from pyramid.view import view_config, view_defaults


@view_defaults(
    route_name="github_payload", renderer="json", request_method="POST"
)
class PayloadView(object):
    """
    View receiving of Github payload. By default, this view it's fired only if
    the request is json and method POST.
    """

    def __init__(self, request):
        self.request = request
        # Payload from Github, it's a dict
        self.payload = self.request.json

    @view_config(header="X-Github-Event:push")
    def payload_push(self):
        """This method is a continuation of PayloadView process, triggered if
        header HTTP-X-Github-Event type is Push"""
        # {u'name': u'marioidival', u'email': u'marioidival@gmail.com'}
        print(self.payload['pusher'])

        # do busy work...
        return "nothing to push payload" # or simple {}

    @view_config(header="X-Github-Event:pull_request")
    def payload_pull_request(self):
        """This method is a continuation of PayloadView process, triggered if
        header HTTP-X-Github-Event type is Pull Request"""
        # {u'name': u'marioidival', u'email': u'marioidival@gmail.com'}
        print(self.payload['pusher'])

        # do busy work...
        return "nothing to pull request payload" # or simple {}

    @view_config(header="X-Github-Event:ping")
    def payload_push_ping(self):
        """This method is responding to a webhook ping"""
        return {'ping': True}


if __name__ == "__main__":
    config = Configurator()

    config.add_route("github_payload", "/github_payload/")
    config.scan()

    app = config.make_wsgi_app()
    server = make_server("0.0.0.0", 8888, app)
    server.serve_forever()
