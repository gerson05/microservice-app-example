package com.elgris.usersapi.api;

import com.elgris.usersapi.models.User;
import com.elgris.usersapi.repository.UserRepository;
import io.jsonwebtoken.Claims;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.web.bind.annotation.*;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.CacheEvict;

import javax.servlet.http.HttpServletRequest;
import java.util.LinkedList;
import java.util.List;

@RestController()
@RequestMapping("/users")
public class UsersController {

    @Autowired
    private UserRepository userRepository;

    // Cache Aside para listado de usuarios
    @Cacheable(value = "usersList")
    @GetMapping("/")
    public List<User> getUsers() {
        List<User> response = new LinkedList<>();
        userRepository.findAll().forEach(response::add);
        return response;
    }

    // Cache Aside para usuario individual
    @Cacheable(value = "users", key = "#username")
    @GetMapping("/{username}")
    public User getUser(HttpServletRequest request, @PathVariable("username") String username) {
        Object requestAttribute = request.getAttribute("claims");
        if((requestAttribute == null) || !(requestAttribute instanceof Claims)){
            throw new RuntimeException("Did not receive required data from JWT token");
        }
        Claims claims = (Claims) requestAttribute;
        if (!username.equalsIgnoreCase((String)claims.get("username"))) {
            throw new AccessDeniedException("No access for requested entity");
        }
        return userRepository.findOneByUsername(username);
    }

    // Evict cache cuando se elimina un usuario
    @CacheEvict(value = "users", key = "#username")
    @DeleteMapping("/{username}")
    public void deleteUser(@PathVariable("username") String username) {
        userRepository.deleteByUsername(username);
    }

    // Evict cache cuando se actualiza un usuario
    @CacheEvict(value = "users", key = "#username")
    @PutMapping("/{username}")
    public User updateUser(@PathVariable("username") String username, @RequestBody User user) {
        user.setUsername(username);
        return userRepository.save(user);
    }
}
