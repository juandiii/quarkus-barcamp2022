package org.acme;

import javax.ws.rs.GET;
import javax.ws.rs.Path;
import javax.ws.rs.Produces;
import javax.ws.rs.core.MediaType;
import java.util.ArrayList;
import java.util.List;

@Path("/hello")
public class GreetingResource {

    List<String> strings = new ArrayList<>();

    public GreetingResource() {
        strings.add("Hello");
        strings.add("World");
    }

    @GET
    @Produces(MediaType.APPLICATION_JSON)
    public List<String> hello() {
        return strings;
    }
}